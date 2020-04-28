require_relative "editor_common"

module Ezframe
  # ページ遷移無しでデータを編集する仕組み
  class SinglePageEditor < PageBase
    include EditorCommon

    def init_vars
      super
      @sort_key = :id
      @event = @parsed_body[:event] if @parsed_body
      @dom_id = { create: "create-area", edit: "edit-area", index: "index-area", detail: "detail-area"}
      # @show_delete_button = nil
    end

    def public_default_get
      @id = get_id
#      if @id
#        return public_detail_post
#      else
        div = [ Ht.div(id: @dom_id[:create], child: make_index_top), Ht.div(id: @dom_id[:index], child: make_index_table) ]
        layout = index_layout(center: Ht.form(child: div))
        return show_base_template(title: Message[:index_page_title], body: Html.convert(layout))
#      end
    end

    def make_index_top
      make_create_button("on=click:url=#{make_base_url}/create")
    end

    def public_default_post
      return { inject: "##{@dom_id[:index]}", body: Html.convert(make_index_table) }
    end

    # 新規データ登録
    def public_create_post
      @form = @event[:form]
      EzLog.debug("public_create_post: event=#{@event}")
      if @event[:cancel]
        return { inject: "##{@dom_id[:create]}", body: Html.convert(make_index_top) }
      elsif !@form
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
      return { inject: "##{@dom_id[:detail]}", body: Html.convert(collection.to_h) }
    end

    def public_delete_post
      @id = get_id
      dataset = DB.dataset(@column_set.name)
      DB.delete(dataset, @id)
      return public_default_post
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
    
    def act_after_edit
      return [public_default_post, public_detail_post]
    end

    def act_after_cancel
      return public_detail_post
    end

    # 一覧表の生成
    def make_index_table
      list = list_for_index
      target_keys = @view_keys
      unless target_keys
        target_keys = @column_set.keys.select {|k| !@column_set[k].no_view?}
      end
      labels = @table_labels
      unless labels
        labels = target_keys.map {|k| @column_set[k].label || "　"}
      end
      # 項目名欄の生成
      thead = Ht.thead(Ht.tr(labels.map {|label| Ht.th(label||"　")}))

      tr_a = list.map do |data|
        view_a = make_index_line(target_keys, data)
        td_a = view_a.map {|view| Ht.td(view)}
        Ht.tr(id: "tr-#{@class_snake}-#{data[:id]}", child: td_a, event: "on=click:url=#{make_base_url(data[:id])}/detail")
      end
      tbody = Ht.tbody(tr_a)
      return [
               Ht.table(id: "enable_datatable_#{@class_snake}", child: [thead, tbody], ezload: "command=enable_datatable:target=#enable_datatable_#{@class_snake}"),
               Ht.div(id: @dom_id[:detail], child: ""),
             ]
    end

    # 一覧表示の１行を生成
    def make_index_line(target_keys, data)
      @column_set.clear
      @column_set.values = data
      return target_keys.map { |key| make_index_column(key) }
    end

    # 一覧表示の１カラムを生成
    def make_index_column(key)
      column = @column_set[key.to_sym]
      if @with_label
        child = [Ht.small(column.label), column.view]
        return Ht.p(id: "edit-#{@class_snake}-#{@column_set[:id].value}-column-#{column.key}", child: child)
      else
        return column.view(force: true)
      end
    end

    # 一覧ページ用のデータリスト生成
    def list_for_index
      return @column_set.dataset.where(deleted_at: nil).order(@sort_key).all
    end

    # 一覧ページ用ボタン
    def button_for_index_line(data)
      Ht.button(class: %w[btn right], event: "on=click:url=#{make_base_url(data[:id])}/edit", child: [Ht.icon("edit"), Message[:edit_button_label]])
    end

    # 詳細ページ用ボタン
    def button_for_detail_box(data)
      buttons = [Ht.button(class: %w[btn right], event: "on=click:url=#{make_base_url(data[:id])}/edit", child: [Ht.icon("edit"), Message[:edit_button_label]]) ]
      if @show_delete_button
        buttons.push(make_delete_button)
      end
      return Ht.div(class: %w[button-box], child: buttons)
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
      send_button = Ht.button(id: "#{@class_snake}-#{command}-finish-button", class: %w[btn], child: [Ht.icon("check"), Message[:edit_finish_button_label]], event: "on=click:url=#{make_base_url(@id)}/#{command}:with=form")
      cancel_button = make_cancel_button("on=click:url=#{make_base_url(@id)}/#{command}:cancel=true:with=form")
      list.push(Ht.p(class: %w[edit-finish-buttons], child: [send_button, cancel_button]))
      return Ht.form(list)
    end

    #  新規登録ボタンの生成
    def make_create_button(event = nil)
      event ||= "on=click:url=#{make_base_url(@id)}/create"
      return Ht.button(id: "#{@class_snake}-create-button", class: %[btn], child: [Ht.icon("add"), Message[:create_button_label]], event: event)
    end

    # 編集ボタンの生成
    def make_edit_button(event = nil)
      event ||= "on=click:url=#{make_base_url(@id)}/edit"
      return Ht.button(class: %w[btn], event: event, child: [ Ht.icon("edit"), Message[:edit_button_label]])    
    end

    # 削除ボタンの生成
    def make_delete_button(event = nil)
      event ||= "on=click:url=#{make_base_url(@id)}/delete"
      return Ht.button(class: %w[btn right red], event: event, child: [Ht.icon("delete"), Message[:delete_button_label]])
    end

    # キャンセルボタンの生成
    def make_cancel_button(event = nil)
      event ||= "on=click:url=#{make_base_url(@id)}/detail:cancel=true:with=form"
      return Ht.button(class: %w[btn red], child: [Ht.icon("cancel"), Message[:cancel_button_label]], event: event)
    end
  end
end
