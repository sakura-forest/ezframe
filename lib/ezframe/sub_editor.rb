require_relative "editor_common"

module Ezframe
  # 各顧客に関連づいた情報の編集を一般化したクラス
  class SubEditor < PageBase
    include EditorCommon

    def init_vars
      super
      @sort_key = :id
      @parent_key = :customer
      @event = @parsed_body[:event] if @parsed_body
      # @use_show_box = true
    end

    def get_parent_id
      params = @request.env["url_params"]
      unless params
        Logger.info "[WARN] no url_params"
        return nil
      end
      return params[@parent_key.to_sym]
    end

    def public_default_post
      return { inject: "##{@class_snake}_tab", body: Html.convert(make_index_page) }
    end

    # 新規データ登録
    def public_create_post
      @form = @event[:form]
      # Logger.debug("public_create_post: form=#{@form}")
      unless @form
        { inject: "##{@class_snake}-create-area", body: Html.convert(make_edit_form(:create)) }
      else
        # 値の保存
        @column_set.clear
        form_values = @form
        form_values.update(@env["url_params"])
        # @column_set.values = form_values
        @column_set[:id].value = @id = @column_set.create(form_values)
        # return { redirect: "#{make_base_url}/#{@id}" }
        return public_default_post
      end
    end

    # データ編集受信
    def public_edit_post
      @id = get_id
      unless @event[:form]
        data = @column_set.set_from_db(@id)
        # フォームの表示
        return show_message_page("no data", "data is not defined: #{@id}") unless data
        form = make_edit_form
        found_a = Ht.search(form, tag: "input")
        found_a.each { |h| h.add_class("#{@class_snake}-edit-box") if h[:size] }
        return { inject: edit_inject_element, body: Html.convert(form) }
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
    def public_show_post
      @id = get_id
      data = @column_set.set_from_db(@id)
      target_keys = @show_keys || @column_set.keys.select { |key| !@column_set[key].attribute[:no_view] }
      line_a = []
      target_keys.each do |key|
        column = @column_set[key]
        v = make_show_line(column)
        line_a.push(v) if v
      end
      table = Ht.div(line_a)
      collection = Materialize::Collection.new
      # 詳細表示用のblockを追加
      collection.push(Ht.div(class: "detail-box", child: [button_for_show_box(data), table]))
      return { inject: "##{@class_snake}_show", body: Html.convert(collection.to_h) }
    end

    def public_delete_post
      @id = get_id
      dataset = DB.dataset(@column_set.name)
      DB.delete(dataset, @id)
      return public_default_post
    end

    # 詳細表示欄の一行を生成
    def make_show_line(column)
      view = column.view
      if view
        view = Ht.pre(view) if view.index("\n")
        return Ht.p([Ht.small(column.label), view])
        #        return Ht.tr([
        #          Ht.td(id: "show-detail-#{@class_snake}-#{column.key}-label", child: Ht.small(column.label)),
        #          Ht.td(id: "show-detail-#{@class_snake}-#{column.key}-value", child: view)
        #        ])
      end
      return nil
    end

    def edit_inject_element
        return "##{@class_snake}_show"
#        return "##{@class_snake}-#{@id}"
#      if @use_show_box
        # 詳細欄に表示
#      else
        # 一覧の情報表示位置に編集欄を表示
#      end
    end
    
    def act_after_edit
      return [public_default_post, public_show_post]
      # return { inject: edit_inject_element, body: Html.convert(make_index_line(@column_set.get_hash(:value))) }
    end

    def act_after_cancel
      return public_show_post
    end

    # 一覧表の生成
    def make_index_page
      list = list_for_index
      # 項目名欄の生成
      if @table_labels
        thead = Ht.thead(Ht.tr(@table_labels.map {|label| Ht.th(label)}))
      else
        thead = Ht.thead(Ht.tr(@view_keys.map {|key| 
          if @column_set[key].respond_to?(:label) 
            Ht.th(@column_set[key].label)
          else
            nil
          end
        })).compact
      end

      tr_a = list.map do |data|
        view_a = make_index_line(data)
        td_a = view_a.map {|view| Ht.td(view)}
        Ht.tr(id: "tr-#{@class_snake}-#{data[:id]}", child: td_a, event: "on=click:url=#{make_base_url(data[:id])}/show")
      end
      tbody = Ht.tbody(tr_a)
      return [
               area_for_create,
               Ht.table(id: "enable_datatable_#{@class_snake}", child: [thead, tbody], event: "on=load:command=enable_datatable:target=#enable_datatable_#{@class_snake}"),
               Ht.div(id: "#{@class_snake}_show"),
             ]
    end

    # 一覧表示の１行を生成
    def make_index_line(data)
      @column_set.clear
      @column_set.values = data
      return @view_keys.map { |key| make_index_column(key) }
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
      return @column_set.dataset.where(@parent_key.to_sym => get_parent_id, deleted_at: nil).order(@sort_key).all
    end

    # 一覧ページ用ボタン
    def button_for_index_line(data)
      Ht.button(class: %w[btn right], event: "on=click:url=#{make_base_url(data[:id])}/edit", child: [Ht.icon("edit"), Message[:edit_button_label]])
    end

    # 詳細ページ用ボタン
    def button_for_show_box(data)
      buttons = [Ht.button(class: %w[btn right], event: "on=click:url=#{make_base_url(data[:id])}/edit", child: [Ht.icon("edit"), Message[:edit_button_label]]) ]
      if @show_delete_button
        buttons.push(make_delete_button)
      end
      return Ht.div(class: %w[button-box], child: buttons)
    end

    #--------------------------------------------------------------------------------------------------------
    # 新規データ追加欄
    def area_for_create
      create_button = make_create_button
      create_button[:event] = "on=click:url=#{make_base_url}/create"
      return Ht.div(id: "#{@class_snake}-create-area", child: create_button)
    end

    # 編集フォームの生成
    def make_edit_form(command = :edit)
      @id = get_id
      target_keys = @edit_keys || @column_set.keys
      list = target_keys.map do |colkey|
        column = @column_set[colkey.to_sym]
        unless column
          Logger.error("undefined column entry: #{colkey}")
          next
        end
        form = column.form
        Ht.p(class: %w[form-line], child: [Ht.small(column.label), form]) if form
      end
      send_button = Ht.button(id: "#{@class_snake}-#{command}-finish-button", class: %w[btn], child: [Ht.icon("check"), Message[:edit_finish_button_label]], event: "on=click:url=#{make_base_url(@id)}/#{command}:with=form")
      cancel_button = make_cancel_button
      cancel_button[:event] = "on=click:url=#{make_base_url(@id)}/#{command}:cancel=true:with=form"
      list.push(Ht.p(class: %w[edit-finish-buttons], child: [send_button, cancel_button]))
      return Ht.form(list)
    end

    #  新規登録ボタンの生成
    def make_create_button
      return Ht.button(id: "#{@class_snake}-create-button", class: %[btn], child: [Ht.icon("add"), Message[:create_button_label]])
    end

    # 編集ボタンの生成
    def make_edit_button
      return Ht.button(class: %w[btn], event: "on=click:url=#{make_base_url(@id)}/edit", child: [ Ht.icon("edit"), Message[:edit_button_label]])    
    end

    # 削除ボタンの生成
    def make_delete_button
      return Ht.button(class: %w[btn right red], event: "on=click:url=#{make_base_url(@id)}/delete", child: [Ht.icon("delete"), Message[:delete_button_label]])
    end

    def make_cancel_button
      return Ht.button(class: %w[btn red], child: [Ht.icon("cancel"), Message[:cancel_button_label]], event: "on=click:url=#{make_base_url(@id)}/show:cancel=true:with=form")
    end
  end
end
