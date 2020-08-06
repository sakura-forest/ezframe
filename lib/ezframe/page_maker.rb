module Ezframe
  module PageMaker
    module Default
      def public_default_get
        @id = get_id
        layout = Layout.new

        # center_box = layout[:center]
        # 追加ボタン配置用のエリア
        content = Ht::List.new
        content.before = [ "button.btn:ezevent=[on=click:url=#{make_base_url}/create] > i.fa.fa-plus", make_extra_buttons ].compact
        # 一覧表示用のエリア
        # center_box.add(id: @dom_id[:index], child: "", ezload: "url=#{make_base_url}")
        layout.embed[:page_title] = Message[:index_page_title]
        layout.embed[:main_content] = content
        EzLog.debug("layout=#{layout.to_ht}")
        return layout
      end

      def public_default_post
        body = Html.convert(make_index_table)
        EzLog.debug("public_default_post: #{body}")
        return { inject: "##{@dom_id[:index]}", body: body, set_url: make_base_url }
      end

      def make_extra_buttons
        nil
      end
    end

    module Index
      # 一覧表の生成
      def make_index_table
        # 表示データの取得
        list = list_for_index

        # 一覧表示カラムの決定
        target_keys = @index_keys
        target_keys = @column_set.keys.select { |k| !@column_set[k].no_view? } unless target_keys

        # テーブル生成
        table = PageStruct::Table.new

        # 項目名欄の生成
        labels = @table_labels
        unless labels
          labels = target_keys.map { |k| @column_set[k].label(force: true) || "　" }
        end
        table.set_head(labels)

        table.set_value(list)
        list.each do |data|
          @column_set.clear
          @column_set.values = data
          line = table.add_line(@column_set.view_array(target_keys))
          # ここのidの生成をどうする？
          line.set_option(ezevent: "on=click:url=#{make_base_url(data[:id])}/detail" )
        end

        # テーブルを表示用に連結
        tb = table.to_ht
        tb[:id] = table_id = "enable_datatable_#{@class_snake}"
        tb[:ezload] = "command=enable_datatable:target=##{table_id}"

        container = PageStruct::Container.new
        vert = container.add_vertical
        vert.add(tb_ht)
        vert.add(Ht.div(id: @dom_id[:detail], child: ""))
        return container.to_ht
      end

      # 一覧ページ用のデータリスト生成
      def list_for_index
        return @column_set.dataset.where(deleted_at: nil).order(@sort_key).all
      end

      # 一覧ページ用ボタン
      def button_for_index_line(data)
        return Ht.button(class: %w[btn right], ezevent: "on=click:url=#{make_base_url(data[:id])}/edit", child: [Ht.icon("edit"), Message[:edit_button_label]])
      end
    end

    module Edit
      # 新規登録フォーム表示(ページ切り替え式)
      def public_create_get
        @column_set.clear
        table = make_edit_form(:create)
        layout = main_layout(center: make_form("#{make_base_url}/create", table), type: 2)
        show_base_template(title: Message[:parent_create_page_title], body: Html.convert(layout))
      end

      # 新規データ登録
      def public_create_post
        edit_base(:create)
      end

      # データ編集受信
      def public_edit_post
        edit_base(:edit)
      end

      def edit_base(typ = :edit)
        @form = event_form
        @id = get_id if typ == :edit
        validation = Valiadtor.new(@column_set.validate(@form))
        if @event[:branch] == "single_validate"
          EzLog.debug("public_#{:typ}_post: single validate:event=#{@event}, form=#{@form}")
          return validate_one(validation, @event[:target_key])
        end
        if @event[:cancel]
          # キャンセルする
          # data = @column_set.set_from_db(@id)
          return act_after_cancel(typ)
        end
        unless @form
          # 入力前。フォームの表示
          case typ
          when :edit
            data = @column_set.set_from_db(@id)
            return show_message_page("no data", "data is not defined: #{@id}") unless data
            # フォームの表示
            form = make_edit_form
            # サイズ指定があったら、CSSクラスを指定。必要？
            # found_a = Ht.search(form, tag: "input")
            # found_a.each { |h| h.add_class("#{@class_snake}-edit-box") if h[:size] }
            return { inject: "##{@dom_id[:detail]}", body: Html.convert(form) }
          when :create
            return { inject: "##{@dom_id[:create]}", body: Html.convert(make_edit_form(:create)) }
          end
        else
          # 入力値を保存
          case typ
          when :edit
            @column_set.update(@id, @event[:form])
            return act_after_edit(:edit)
          when :create
            values = {}
            values.update(@form)
            values.update(path_params)
            @column_set[:id].value = @id = @column_set.create(form_values)
            return act_after_edit(:create)
          end
        end
      end

      # 編集フォームの生成
      def make_edit_form(typ = :edit)
        target_keys = @edit_keys || @column_set.edit_keys
        form = PageStruct::Form.new
        form.action = "#{make_base_url}/#{typ}"
        target_keys.map do |key|
          key = key.to_sym
          form.add(make_edit_line(key))
        end
        cancel_button = make_cancel_button("on=click:url=#{make_base_url(@id)}/#{typ}:cancel=true:with=form")
        send_button = edit_finish_button
        form.add(Ht.p(class: %w[edit-finish-buttons], child: [send_button, cancel_button]))
        return form
      end

      # 編集ページの行を生成
      def make_edit_line(key)
        column = @column_set[key]
        unless column
          EzLog.error("undefined column entry: #{key}")
          return nil
        end
        input = column.form
        if input
          return Ht.p(class: %w[form-line], child: [Ht.small(column.label), input ]) 
        end
        return nil 
      end

      # 編集完了ボタン
      def edit_finish_button(typ = :edit, event = nil)
        msg = Message("#{typ}_finish_button_label")
        event ||= "on=click:url=#{make_base_url(@id)}/#{typ}:with=form"
        btn = Ht.button(id: "#{@class_snake}-#{typ}-finish-button", class: %w[btn], 
          child: [ Ht.icon("check"), msg ], 
          ezevent: event
        )
        return btn
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

      # キャンセル時の表示
      def act_after_cancel
        return public_detail_post
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
