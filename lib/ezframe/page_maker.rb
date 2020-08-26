module Ezframe
  module PageMaker
    module Default
      def public_default
        @id ||= get_id
        if @id
          # idがあったら、詳細表示
          return public_detail
        else
          # idがなかったら、一覧表示
          @index_page_maker ||= IndexPageMaker
          maker = @index_page_maker.new(self)
          content = maker.make_content
          page_title = Message[:index_page_title]
        end
        if @request.xhr?
          content[:inject] = "#main-content"
          return content
        else
          layout = Layout.new
          layout.embed[:main_content] = content.to_ht
          return layout
        end
      end

#      def public_default_post
#        if @request.xhr?
#          maker = @index_page_maker.new(self)
#          EzLog.debug("public_default_post: #{body}")
#          return { inject: "##{@dom_id[:index]}", body: Html.convert(maker.make_content), url: make_base_url }
#        else
#          return public_default_get
#        end
#      end

      # 一覧ページ用のデータリスト生成
      def list_for_index(where = nil)
        where ||= {}
        where.update(deleted_at: nil)
        # EzLog.debug("where: #{where}")
        return @column_set.dataset.where(where).order(@sort_key).all
      end
    end

    class IndexPageMaker
      def initialize(parent)
        @parent = parent
        @controller = @parent.controller
      end

      # 一覧表の生成
      def make_content
        # 表示データの取得
        list = @parent.list_for_index

        # 一覧表示カラムの決定
        target_keys = @parent.index_keys || @parent.column_set.index_keys || @parent.column_set.view_keys

        # テーブル生成
        table = Ht::Table.new(wrap_tag: "table.table.table-bordered.dataTable")

        # 項目名欄の生成
        labels = @table_labels
        unless labels
          labels = target_keys.map { |k| @parent.column_set[k].label(force: true) || "　" }
        end
        table.header = labels

        list.each do |data|
          @parent.column_set.clear
          @parent.column_set.values = data
          table.add_item(@parent.column_set.view_array(target_keys), row_attr: { ezevent: "on=click:url=#{@parent.make_base_url(data[:id])}/detail" })
        end
        table.add_before(Ht.from_array([ "button.btn.btn-primary#create-btn:ezevent=[on=click:url=#{@parent.make_base_url}/create]", [ "i.fa.fa-plus", "text:#{Message[:create_button_label]}" ] ]))
        return table
      end

      # 一覧ページ用ボタン
      #def button_for_index_line(data)
      #  return Ht.button(class: %w[btn right], ezevent: "on=click:url=#{make_base_url(data[:id])}/edit", child: [Ht.icon("edit"), Message[:edit_button_label]])
      #end
    end

    module Edit
      # 新規データ登録
      def public_create
        @typ ||= :create
        content = branch(@typ)
        if @request.xhr?
          content[:inject] = "#main-content"
          return content
        else
          layout = Layout.new
          maker = @edit_page_maker.new(self)
          layout.embed[:main_content] = content[:body]
          return layout
        end
      end

      # 顧客データ編集
      def public_edit
        @typ = :edit
        public_create
      end

      # 新規データ登録
#      def public_create_post
        # p@edit_page_maker ||= EditPageMaker
        # maker = @edit_page_maker.new(@controller, self)
#        return branch(:create)
#      end

      # データ編集受信
#      def public_edit_post
#        return branch(:edit)
#      end

      def branch(typ = :edit)
        @ezevent = @controller.ezevent
        EzLog.debug("Edit.branch: ezevent: #{@ezevent}")
        @edit_page_maker ||= EditPageMaker
        if @ezevent[:branch] == "single_validate"
          EzLog.debug("Edit.branch: single_validate")
          validation = Validator.new(@parent.column_set.validate(@controller.event_form))
          return validation.validate_one(@ezevent[:target_key])
        elsif @ezevent[:cancel]
          return act_after_cancel
        end

        maker = @edit_page_maker.new(self)
        if @controller.event_form
          EzLog.debug("Edit.branch: store edit values")
          # 入力後。フォーム内容をDBに格納
          validation = Validator.new(@column_set.validate(@controller.event_form))
          cmd_a = validation.validate_all
          if cmd_a.length > 0
            EzLog.debug("validate_all: #{cmd_a}")
            return cmd_a
          end
          if typ == :create
            maker.store_create_form
          else
            maker.store_edit_form
          end
          act_after_edit(typ)
        else
          EzLog.debug("Edit.branch: show_form")
          # 入力前。フォームを表示
          if typ == :create
            return maker.show_create_form
          else
            return maker.show_edit_form
          end
        end
      end

      # キャンセル時の表示
      def act_after_cancel
        return public_detail
      end

      # 編集完了後の表示
      def act_after_edit(typ)
        case typ
        when :edit
          return [public_default_post, public_detail_post]
        when :create
          return { redirect: make_base_url(@id) }
        end
      end
    end

    class EditPageMaker
      include EditorCommon

      def initialize(parent)
        @parent = parent
        @controller = @parent.controller
        @ezevent = @controller.ezevent
      end

      # 新規登録フォームの表示
      def show_create_form
#         return { inject: "#main-content", body: Html.convert(make_edit_form(:create)), set_url: [ "#{@parent.make_base_url}/create", "新規登録" ] }
        return { body: make_edit_form(:create), url: "#{@parent.make_base_url}/create", title: "新規登録" }
      end

      # 編集フォームの表示
      def show_edit_form
        @id = @parent.get_id
        data = @parent.column_set.set_from_db(@id)
        return show_message_page("no data", "data is not defined: #{@id}") unless data
        # フォームの表示
        form = make_edit_form(:edit)
#         return { inject: "#main-content", body: Html.convert(form), set_url: [ "#{@parent.make_base_url}/edit", "情報編集" ] }
        return { body: form, url: "#{@parent.make_base_url}/edit", title: "情報編集: #{data[:m_name]}, #{data[:f_name]}" }
      end

      def store_edit_form
        @id = get_id
        @column_set.update(@id, ezevent[:form])
      end

      def store_create_form
        values = {}
        values.update(@ezevent[:form])
        values.update(@controller.route_params)
        EzLog.debug("store_create_form: #{values}")
        @parent.column_set[:id].value = @id = @parent.column_set.create(values)
      end

      # 編集フォームの生成
      def make_edit_form(typ = :edit)
        target_keys = @parent.column_set.edit_keys
        new_form = Bootstrap::Form.new
        new_form.action = "#{@parent.make_base_url}/#{typ}"
        target_keys.map { |key| make_edit_line(new_form, key) }
        cancel_button = make_cancel_button("on=click:url=#{@parent.make_base_url(@id)}/#{typ}:cancel=true:with=form")
        send_button = edit_finish_button
        new_form.append = Ht.from_array([ "div", [send_button, cancel_button] ])
        return new_form
      end

      # 編集ページの行を生成
      def make_edit_line(form, key)
        column = @parent.column_set[key.to_sym]
        unless column
          EzLog.error("undefined column entry: #{key}")
          return nil
        end
        inpgrp = form.add_input(column.form)
        inpgrp.add_prepend("text:#{column.label}")
        return inpgrp
      end

      # 編集完了ボタン
      def edit_finish_button(typ = :edit, event = nil)
        msg = Message["#{typ}_finish_button_label"]
        event ||= "on=click:url=#{@parent.make_base_url(@id)}/#{typ}:with=form"
        return [ "button.btn.btn-primary#edit-finish-button:ezevent=[#{event}]", [ "i.fa.fa-check", "span:#{msg}" ] ]
      end
    end

    # 詳細表示ページ生成キット
    module Detail
      # データ詳細表示
      def public_detail
        @id ||= get_id
        @detail_page_maker ||= DetailPageMaker
        maker = @detail_page_maker.new(self)
        data = @column_set.set_from_db(@id)
        # EzLog.debug("Detail::public_detail_post: id=#{@id}, data=#{data}")
        content = maker.make_content
        content = content.to_ht if content.respond_to?(:to_ht)
        if @request.xhr?
          return { inject: "#main-content", body: Html.convert(content), set_url: [ "#{make_base_url}/detail", "顧客情報" ] }
        else
          layout = Layout.new
          layout.embed[:main_content] = content
          return layout
        end
      end

      def public_detail_get
        @id ||= get_id
        @detail_page_maker ||= DetailPageMaker
        maker = @detail_page_maker.new(self)
        @column_set.set_from_db(@id)
        content = maker.make_content
        layout = Layout.new
        layout.embed[:main_content] = content
        return layout
      end
    end

    class DetailPageMaker
      def initialize(parent)
        @parent = parent
        @controller = @parent.controller
      end

      def make_content
        target_keys = @detail_keys || @parent.column_set.view_keys
        list = Ht::List.new
        target_keys.each do |key|
          column = @parent.column_set[key]
          row = make_detail_line(column)
          list.add_item(row) if row
        end
        list.add_item(button_for_detail_box)
        return list
        # buttons = holizon.add_vertical
      end

      # 詳細表示欄の一行を生成
      def make_detail_line(column)
        view = column.view
        if view
          if view.strip.index("\n")
            view = Ht.pre(view) 
          else
            view = Ht.span(view)
          end
          return Ht.from_array([ "p", [ "small.text-secondary:#{column.label}", view ] ])
        end
        return nil
      end

      def button_for_detail_box(data)
        buttons = [ Ht.button(class: %w[btn right], ezevent: "on=click:url=#{make_base_url(data[:id])}/edit", child: [Ht.icon("edit"), Message[:edit_button_label]])]
        if @show_delete_button
          buttons.push(make_delete_button)
        end
        return Ht.div(class: %w[button-box], child: buttons)
      end
    end

    module Delete
      def public_delete_post
        @id ||= get_id
        dataset = DB.dataset(@column_set.name)
        DB.delete(dataset, @id)
        return public_default_post
      end
    end
  end
end
