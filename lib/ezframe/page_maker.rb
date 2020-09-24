module Ezframe
  module PageMaker
    class PageContent
      attr_accessor :body, :title, :url

      def to_ht
        return @body.respond_to?(:to_ht) ? @body.to_ht : @body
      end
    end

    module Default
      def public_default
        @id ||= get_id
        if @id
          # idがあったら、詳細表示
          public_detail
          return
        end
        # 一覧表示
        public_index
      end

      # 一覧表示
      def public_index
        @index_page_maker ||= IndexPageMaker
        maker = @index_page_maker.new(self)
        content = maker.make_content
        if @request.xhr?
          EzLog.debug("public_index: response=#{@response}")
          @response.command  = { inject: @target_box || "#main-content" }
          @response.body = content
          if @set_history
            @response.set_url = @request.path_info
            @response.title = "データ一覧"
          end
        else
          layout = Layout.new
          layout.embed[:body] = content.body
          @response.body = layout
        end
      end

      # 一覧ページ用のデータリスト生成
      def list_for_index(where = nil)
        where ||= {}
        where.update(deleted_at: nil)
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
        table = Ht::Table.new(wrap_tag: Ht.compact("table.table.table-bordered.dataTable"))

        # 項目名欄の生成
        labels = @table_labels
        unless labels
          labels = target_keys.map do |k| 
            column = @parent.column_set[k]
            if column
              column.label(force: true) || "　"
            else
              EzLog.error("IndexPageMaker.make_content: no column defined: #{k}")
              "　"
            end
          end
        end
        table.header = labels

        list.each do |data|
          @parent.column_set.clear
          @parent.column_set.values = data
          table.add_item(@parent.column_set.view_array(target_keys), row_attr: { ezevent: "on=click:url=#{@parent.make_base_url(data[:id])}/detail" })
        end
        table.add_before(Ht.compact([ "button.btn.btn-primary#create-btn:ezevent=[on=click:url=#{@parent.make_base_url}/create]", [ "i.fa.fa-plus", "text:#{Message[:create_button_label]}" ] ]))

        content = PageContent.new
        content.body = table_ht = table.to_ht
        elem = Ht.search(table_ht, "table")
        elem[:ezload] = "command=enable_datatable"
        content.title = Message[:index_page_title]
        return content
      end
    end

    module Edit
      # 新規データ登録
      def public_create
        @typ ||= :create
        content = branch(@typ)
        return unless content
        if @request.xhr?
          @response.body = content
          @response.command = { inject: @target_box || "#main-content" }
          if @set_history
            @response.set_url = @request.path_info
            @response.title = content.title if content.respond_to?(:title)
          end
        else
          layout = Layout.new
          layout.embed[:main_content] = content.body
          layout.embed[:page_title] = content.title
          @response.body = layout
        end
      end

      # 顧客データ編集
      def public_edit
        @typ = :edit
        public_create
      end

      def branch(typ = :edit)
        @id ||= get_id
        @ezevent = @controller.ezevent
        # EzLog.debug("Edit.branch: ezevent: #{@ezevent}")
        @edit_page_maker ||= EditPageMaker
        if @ezevent[:branch] == "single_validate"
          EzLog.debug("Edit.branch: single_validate")
          validation = Validator.new(@parent.column_set.validate(@controller.event_form))
          @response.command = validation.validate_one(@ezevent[:target_key])
          return nil
        elsif @ezevent[:cancel]
          @response.command = { redirect: "#{@parent.make_base_url}/#{@id}" }
          return nil
        end

        maker = @edit_page_maker.new(self)
        EzLog.debug("event_form=#{@controller.event_form}")
        event_form = @controller.event_form
        if event_form
          EzLog.debug("Edit.branch: store edit values")
          # 入力後。フォーム内容をDBに格納
          validation = Validator.new(@column_set.validate(event_form))
          if validation.count_errors > 0
            cmd_a = validation.validate_all
            EzLog.debug("validate_all: #{cmd_a}")
            @response.command = cmd_a
            return nil
          end
          if typ == :create
            @id = maker.store_create_form
          else
            maker.store_edit_form
          end
          public_detail
          return nil
        else
          EzLog.debug("Edit.branch: show_form")
          # 入力前。フォームを表示
          if typ == :create
            content = maker.show_create_form
            raise if content.is_a?(String)
          else
            content = maker.show_edit_form
            raise if content.is_a?(String)
          end
          return content
        end
      end
    end

    class EditPageMaker
      include EditorCommon

      def initialize(parent)
        @parent = parent
        @controller = @parent.controller
        @response = @controller.response
        @ezevent = @controller.ezevent
      end

      # 新規登録フォームの表示
      def show_create_form
        content = make_edit_form(:create)
        content.title = "新規登録"
        return content
      end

      # 編集フォームの表示
      def show_edit_form
        @id ||= @parent.id
        data = @parent.column_set.set_from_db(@id)
        return show_message_page("no data", "data is not defined: #{@id}") unless data
        content = make_edit_form(:edit)
        content.title = "情報編集: #{data[:m_name]}, #{data[:f_name]}"
        return content
      end

      # フォームをDBに格納
      def store_edit_form
        @id ||= @parent.get_id
        @column_set.update(@id, ezevent[:form])
      end

      def store_create_form
        values = {}
        values.update(@ezevent[:form])
        values.update(@controller.route_params)
        EzLog.debug("store_create_form: #{values}")
        @parent.column_set[:id].value = @id = @parent.column_set.create(values)
        return @id
      end

      # 編集フォームの生成
      def make_edit_form(typ = :edit)
        target_keys = @parent.column_set.edit_keys
        new_form = Bootstrap::Form.new
        new_form.action = "#{@parent.make_base_url}/#{typ}"
        target_keys.map { |key| make_edit_line(new_form, key) }
        cancel_button = make_cancel_button("on=click:url=#{@parent.make_base_url(@id)}/#{typ}:cancel=true:with=form")
        send_button = edit_finish_button
        new_form.append = Ht.compact("div", [send_button, cancel_button])
        content = Content.new
        content.body = new_form
        return content
      end

      # 編集ページの行を生成
      def make_edit_line(form, key)
        column = @parent.column_set[key.to_sym]
        unless column
          EzLog.error("undefined column entry: #{key}")
          return nil
        end
        inpgrp = form.add_input(column.form)
        inpgrp.add_prepend(column.label)
        return inpgrp
      end

      # 編集完了ボタン
      def edit_finish_button(typ = :edit, event = nil)
        msg = Message["#{typ}_finish_button_label"]
        event ||= "on=click:url=#{@parent.make_base_url(@id)}/#{typ}:with=form"
        return Ht.compact("button.btn.btn-primary#edit-finish-button:ezevent=[#{event}]", [ "i.fa.fa-check", "span:#{msg}" ])
      end
    end

    # 詳細表示ページ生成キット
    module Detail
      # データ詳細表示
      def public_detail
        @id ||= get_id
        @detail_page_maker ||= DetailPageMaker
        maker = @detail_page_maker.new(self)
        @column_set.set_from_db(@id)
        content = maker.make_content
        if @request.xhr?
          @response.command = { inject: @target_box || "#main-content" }
          @response.body = content
          if @set_history
            @response.set_url = make_base_url
            @response.title =  "詳細情報"
          end
          # EzLog.debug("public_detail.AJAX: #{@response}")
        else
          layout = Layout.new
          layout.embed[:main_content] = Ht.compact("div:ezload=[url=#{make_base_url}]")
          @response.body = layout
        end
        return nil
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
        content = PageContent.new
        content.body = list
        return content
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
          return Ht.compact("p", [ "small.text-secondary:#{column.label}", view ])
        end
        return nil
      end

      def button_for_detail_box(data)
        buttons = Ht.compact("button.btn.btn-primary:ezevent=[on=click:url=#{make_base_url(data[:id])}/edit]", [ "i.fas.fa-edit", "span:#{Message[:edit_button_label]}" ])
        buttons += make_delete_button if @show_delete_button
        return Ht.compact(".button-box", buttons)
      end
    end

    module Delete
      def public_delete_post
        @id ||= get_id
        dataset = DB.dataset(@column_set.name)
        DB.delete(dataset, @id)
        return public_default
      end
    end
  end
end
