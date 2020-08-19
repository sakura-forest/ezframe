module Ezframe
  module PageMaker
    module Default
      def public_default_get
        @id = get_id
        layout = Layout.new

        # center_box = layout[:center]
        # 追加ボタン配置用のエリア
        content = Ht::List.new
        # 一覧表示用のエリア
        # center_box.add(id: @dom_id[:index], child: "", ezload: "url=#{make_base_url}")
        @index_page_maker ||= IndexPageMaker
        maker = @index_page_maker.new(@controller, self)
        layout.embed[:page_title] = Message[:index_page_title]
        content = maker.make_content
        content.add_before(Ht.from_array([ "button.btn.btn-primary#create-btn:ezevent=[on=click:url=#{make_base_url}/create]", [ "i.fa.fa-plus", "text:#{Message[:create_button_label]}" ] ]))
        layout.embed[:main_content] = content.to_ht
        # EzLog.debug("layout=#{layout.to_ht}")
        return layout
      end

      def public_default_post
        body = Html.convert(make_index_table)
        EzLog.debug("public_default_post: #{body}")
        return { inject: "##{@dom_id[:index]}", body: body, set_url: make_base_url }
      end
    end

    class IndexPageMaker
      def initialize(ctrl, pa)
        @controller = ctrl
        @parent = pa
      end

      # 一覧表の生成
      def make_content
        # 表示データの取得
        list = list_for_index

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
          @column_set.clear
          @column_set.values = data
          table.add_item(@column_set.view_array(target_keys), row_attr: { ezevent: "on=click:url=#{make_base_url(data[:id])}/detail" })
        end
        return table
        # テーブルを表示用に連結
        # tb = table.to_ht
        # tb[:id] = table_id = "enable_datatable_#{@class_snake}"
        # tb[:ezload] = "command=enable_datatable:target=##{table_id}"

        #container = PageStruct::Container.new
        #vert = container.add_vertical
        #vert.add(tb_ht)
        #vert.add(Ht.div(id: @dom_id[:detail], child: ""))
        #return container.to_ht
      end

      # 一覧ページ用のデータリスト生成
      def list_for_index
        return @parent.column_set.dataset.where(deleted_at: nil).order(@sort_key).all
      end

      # 一覧ページ用ボタン
      def button_for_index_line(data)
        return Ht.button(class: %w[btn right], ezevent: "on=click:url=#{make_base_url(data[:id])}/edit", child: [Ht.icon("edit"), Message[:edit_button_label]])
      end
    end

    module Edit
      # 新規データ登録
      def public_create_post
        @edit_page_maker ||= EditPageMaker
        maker = @edit_page_maker.new(@controller, self)
        return branch(:create)
      end

      # データ編集受信
      def public_edit_post
        return branch(:edit)
      end

      def branch(typ = :edit)
        @ezevent = @controller.ezevent
        @edit_page_maker ||= EditPageMaker
        if @ezevent[:branch] == "single_validate"
          validation = Validator.new(@parent.column_set.validate(@form))
          return Validator.new.validate_one(validation, @ezevent[:target_key])
        elsif @ezevent[:cancel]
          return :cancel
        end

        maker = @edit_page_maker.new(@controller, self)
        if @controller.event_form
          # 入力後。フォーム内容をDBに格納
          if typ == :create
            maker.store_create_form
          else
            maker.store_edit_form
          end
        else
          # 入力前。フォームを表示
          if typ == :create
            maker.show_create_form
          else
            maker.show_edit_form
          end
        end
      end

      # キャンセル時の表示
      def act_after_cancel
        return public_detail_post
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

      def initialize(ctrl, parent)
        @controller = ctrl
        @parent = parent
        @ezevent = @controller.ezevent
      end

      # 新規登録フォームの表示
      def show_create_form
        return { inject: "#main-content", body: Html.convert(make_edit_form(:create)) }
      end

      # 編集フォームの表示
      def show_edit_form
        @id = get_id
        data = @parent.column_set.set_from_db(@id)
        return show_message_page("no data", "data is not defined: #{@id}") unless data
        # フォームの表示
        form = make_edit_form(:edit)
        return { inject: "#main-content", body: Html.convert(form) }
      end

      def store_edit_form
        @id = get_id
        @column_set.update(@id, ezevent[:form])
        return act_after_edit(:edit)
      end

      def store_create_form
        values = {}
        values.update(@ezevent[:form])
        values.update(path_params)
        @parent.column_set[:id].value = @id = @parent.column_set.create(form_values)
        return act_after_edit(:create)
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
        return [ "button.btn.btn-primary:ezevent=[#{event}]", [ "i.fa.fa-check", "text:#{msg}" ] ]
      end
    end

    # 詳細表示ページ生成キット
    module Detail
      # データ詳細表示
      def public_detail_post
        @id ||= get_id
        data = @column_set.set_from_db(@id)
        target_keys = @detail_keys || @column_set.view_keys
        container = Container.new
        holizon = container.add_holizontal
        detail_list = holizon.add_vertical
        buttons = holizon.add_vertical
        buttons.add(button_for_detail_box)

        target_keys.each do |key|
          column = @column_set[key]
          row = make_detail_line(column)
          detail_list.add(row) if row
        end
        return { inject: "##{@dom_id[:detail]}", body: container.to_ht }
      end

      # 詳細表示欄の一行を生成
      def make_detail_line(column)
        view = column.view
        if view
          view = Ht.pre(view) if view.strip.index("\n")
          return Ht.p([Ht.small(column.label), view])
        end
        return nil
      end

      def button_for_detail_box(data)
        buttons = [Ht.button(class: %w[btn right], ezevent: "on=click:url=#{make_base_url(data[:id])}/edit", child: [Ht.icon("edit"), Message[:edit_button_label]])]
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
