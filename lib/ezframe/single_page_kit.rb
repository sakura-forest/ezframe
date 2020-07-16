module Ezframe
  module PageKit
    module Default
      def public_default_get
        @id = get_id
        div_a = [
          # 追加ボタン配置用のエリア
          Ht.div(id: @dom_id[:create], child: make_index_top), 
          # 一覧表示用のエリア
          Ht.div(id: @dom_id[:index], child: "", ezload: "url=#{make_base_url}")
        ]
        layout = index_layout(center: make_form(make_base_url, div_a))
        return show_base_template(title: Message[:index_page_title], body: Html.convert(layout))
      end

      def public_default_post
        return { inject: "##{@dom_id[:index]}", body: Html.convert(make_index_table), set_url: make_base_url }
      end
    end

    module Index
      def make_index_top
        make_create_button("on=click:url=#{make_base_url}/create")
      end

      # 一覧表の生成
      def make_index_table
        list = list_for_index
        target_keys = @index_keys
        unless target_keys
          target_keys = @column_set.keys.select { |k| !@column_set[k].no_view? }
        end

        table = PageStructure::Table.new

        # 項目名欄の生成
        labels = @table_labels
        unless labels
          labels = target_keys.map { |k| @column_set[k].label(force: true) || "　" }
        end
        # thead = Ht.thead(Ht.tr(labels.map { |label| Ht.th(label || "　") }))
        table.set_head(labels)

        table.set_value(list)
        list.each do |data|
          @column_set.clear
          @column_set.values = data
          table.add_line(@column_set.view_array(target_keys))
        end
        tb_ht = table.to_ht
        tb_ht[:id] = table_id = "enable_datatable_#{@class_snake}"
        tb_ht[:ezload] = "command=enable_datatable:target=##{table_id}"
        return [
          # Ht.table(id: "enable_datatable_#{@class_snake}", child: [thead, tbody])
          tb_ht,
          Ht.div(id: @dom_id[:detail], child: ""),
        ]
      end

      # 一覧表示の１行を生成(override用)
#      def make_index_line(target_keys, data)
#        make_index_line_event(target_keys, data)
        # make_index_line_href(target_keys, data)
#      end

      # 一覧表示の１行を生成(イベント型)
#      def make_index_line_event(target_keys, data)
        # td_a = target_keys.map { |k| Ht.td(make_index_column(k)) }
        # return Ht.tr(id: "tr-#{@class_snake}-#{data[:id]}", child: td_a, ezevent: "on=click:url=#{make_base_url(data[:id])}/detail")
#        make_index_column(k)
#      end

      # 一覧の一行を生成（href型)
#      def make_index_line_href(target_keys, data)
#        td_a = target_keys.map do |k| 
#          Ht.td(Ht.a(href: "#{make_base_url(data[:id])}/detail", child: make_index_column(k))
#        end
#        return Ht.tr(td_a)
#      end

            # 一覧表示の１カラムを生成
      def make_index_column(key)
        column = @column_set[key.to_sym]
        return column.view(force: true)
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
        @form = @event[:form]
        EzLog.debug("public_create_post: event=#{@event}")
        # １項目のバリデーション
        validator = Valiadtor.new(@column_set.validate(@form))
        if @event[:branch] == "single_validate"
          EzLog.debug("public_create_post: single validate")
          return validator.single_validation(@event[:target_key] || @form.keys[0])
        end
        # キャンセルの場合、編集欄を新規ボタンに戻す
        if @event[:cancel]
          return { inject: "##{@dom_id[:create]}", body: Html.convert(make_index_top) }
        elsif !@form
          # フォームがない場合はフォームの表示
          return { inject: "##{@dom_id[:create]}", body: Html.convert(make_edit_form(:create)) }
        else
          # 値の保存
          @column_set.clear
          form_values = @form
          form_values.update(@env["url_params"])
          # @column_set.values = form_values
          @column_set[:id].value = @id = @column_set.create(form_values)
          return { redirect: make_base_url(@id) }
          # return public_default_post
        end
      end

      # データ編集受信
      def public_edit_post
        @id = get_id
        validation = Valiadtor.new(@column_set.validate(@form))
        if @event[:branch] == "single_validate"
          EzLog.debug("public_edit_post: single validate:event=#{@event}, form=#{@form}")
          return single_validation(validation, @event[:target_key])
        end
        unless @event[:form]
          data = @column_set.set_from_db(@id)
          return show_message_page("no data", "data is not defined: #{@id}") unless data
          # フォームの表示
          form = make_edit_form
          found_a = Ht.search(form, tag: "input")
          found_a.each { |h| h.add_class("#{@class_snake}-edit-box") if h[:size] }
          return { inject: "##{@dom_id[:detail]}", body: Html.convert(form) }
        else
          if @event[:cancel]
            data = @column_set.set_from_db(@id)
            return act_after_cancel
          else
            # 値を保存
            @column_set.update(@id, @event[:form])
          end
          return act_after_edit
        end
      end

      # 編集フォームの生成
      def make_edit_form(command = :edit)
        @id ||= get_id
        target_keys = @edit_keys || @column_set.keys
        list = target_keys.map do |colkey|
          column = @column_set[colkey.to_sym]
          unless column
            EzLog.error("undefined column entry: #{colkey}")
            next
          end
          form = column.form
          Ht.p(class: %w[form-line], child: [Ht.small(column.label), form]) if form
        end
        send_button = Ht.button(id: "#{@class_snake}-#{command}-finish-button", class: %w[btn], child: [Ht.icon("check"), Message[:edit_finish_button_label]], ezevent: "on=click:url=#{make_base_url(@id)}/#{command}:with=form")
        cancel_button = make_cancel_button("on=click:url=#{make_base_url(@id)}/#{command}:cancel=true:with=form")
        list.push(Ht.p(class: %w[edit-finish-buttons], child: [send_button, cancel_button]))
        return make_form("#{make_base_url}/edit", list)
      end

      def edit_cancel_button
        Ht.span(class: %w[btn red small waves-effect waves-light switch-button], child: Ht.icon("clear"))
      end

      # 編集完了後の表示
      def act_after_edit
        return [public_default_post, public_detail_post]
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
        target_keys = @detail_keys || @column_set.keys.select { |key| !@column_set[key].attribute[:no_view] }
        line_a = []
        target_keys.each do |key|
          column = @column_set[key]
          v = make_detail_line(column)
          line_a.push(v) if v
        end
        table = Ht.div(line_a)
        collection = Materialize::Collection.new
        # 詳細表示用のblockを追加
        collection.push(Ht.div(id: @dom_id[:detail], child: [button_for_detail_box(data), table]))
        return { inject: "##{@dom_id[:detail]}", body: Html.convert(collection.to_ht) }
      end

      # 詳細ページ用ボタン
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
        @id = get_id
        dataset = DB.dataset(@column_set.name)
        DB.delete(dataset, @id)
        return public_default_post
      end
    end
  end
end
