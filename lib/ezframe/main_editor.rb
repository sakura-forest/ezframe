# frozen_string_literal: true
module Ezframe
  class MainEditor < PageBase
    include EditorCommon

    # 一覧ページ生成
    def public_default_get
      @id = get_id
      if @id
        return make_detail_page
      else
        data_a = list_for_index
        div = [ Ht.div(id: "detail-top-area", child: make_index_top), Ht.div(id: "index-area", child: make_index_table(data_a)) ]
        layout = index_layout(center: Ht.form(child: div))
        return show_base_template(title: Message[:index_page_title], body: Html.convert(layout))
      end
    end

    # 一覧ページの上部に表示するボタン等の生成
    def make_index_top
      make_create_button
    end

    # 新規登録フォーム表示
    def public_create_get
      @column_set.clear
      table = make_edit_form(:create)
      layout = main_layout(center: Ht.form(child: table), type: 2)
      show_base_template(title: Message[:parent_create_page_title], body: Html.convert(layout))
    end

    # 新規登録受信
    def public_create_post
      validation = @column_set.validate(@form)
      if @event[:branch] == "single_validate"
        EzLog.debug("public_create_post: single validate: event=#{@event}, form=#{@form}")
        return single_validation(validation, @event[:target_key]) 
      end
      unless @form
        return { inject: "#center-panel", body: Ht.form(child: make_edit_form(:create)) }
      else
        if count_errors(validation) > 0
          cmd_a = full_validation(validation)
          EzLog.debug("public_create_post: cmd_a=#{cmd_a}")
          return cmd_a if cmd_a.length > 0
        end
        # 値の保存
        id = create_data(@form)
        return { redirect: make_base_url(id) }
      end
    end


    # データ編集受信
    def public_edit_post
      EzLog.debug("public_edit_post: #{@form}")
      @id = get_id
      validation = @column_set.validate(@form)
      if @event[:branch] == "single_validate"
        EzLog.debug("public_edit_post: single validate:event=#{@event}, form=#{@form}")
        return single_validation(validation, @event[:target_key]) 
      end
      unless @form
        data = @column_set.set_from_db(@id)
        return show_message_page("no data", "data is not defined: #{@id}") unless data
        return { inject: "#center-panel", body: Html.convert(Ht.form(make_edit_form)) }
      else
        if count_errors(validation) > 0
          cmd_a = full_validation(validation)
          return cmd_a 
        end
        # 値を保存
        update_data(@id, @form)
        return { redirect: make_base_url(@id) }
      end
    end

    private

    # 新規データの生成
    def create_data(form)
      @column_set.clear
      @column_set[:id].value = id = @column_set.create(form)
      return id
    end

    # データの更新
    def update_data(id, form)
      @column_set.update(id, form)
    end

    # 自動入力を行う
    def exec_completion
      return nil
    end

    # 一覧テーブルの生成
    def make_index_table(data_a)
      target_keys = @index_keys
      unless target_keys
        target_keys = @column_set.keys.select {|k| !@column_set[k].no_view? }
      end
      tr_a = data_a.map do |data|
        @column_set.clear
        @column_set.set_values(data, from_db: true)
        line = target_keys.map do |key| 
          view = @column_set[key].view
          Ht.td(Ht.a(href: "#{make_base_url(data[:id])}", child: view))
        end
        Ht.tr(line)
      end
      th_a = target_keys.map {|key| Ht.th(@column_set[key.to_sym].label) }
      thead = Ht.thead(Ht.tr(th_a))
      tbody = Ht.tbody(tr_a)
      table_id = "enable_datatable_#{@class_snake}"
      return Ht.table(id: table_id, class: %w[enable_datatable], child: [ thead, tbody ], ezload: "command=enable_datatable:target=##{table_id}:size=10")
    end

    # 編集フォームの生成
    def make_edit_form(command = :edit)
      table = []
      matrix = @column_set.map do |column|
        next if column.no_edit?
        form = column.form
        table.push Ht.p([ Ht.small(column.label), form ]) if form
      end
      send_button = Ht.button(id: "edit-finish-button", child: Message[:edit_finish_button_label], class: %w[btn], event: "on=click:url=#{make_base_url}/#{command}:with=form") 
      cancel_button = edit_cancel_button
      cancel_button[:event] = "on=click:command=redirect:url=#{make_base_url}"
      table.push(Ht.p([send_button, cancel_button]))
      return table
    end

    # 詳細表示
    def make_detail_page
      # EzLog.info "make_detail_page: #{@request.params.inspect}"
      id = get_id(@class_snake)
      unless @column_set.set_from_db(id)
        return show_message_page("no data", "data is not defined: #{id}")
      end
      right = nil
      right = right_tabs if @with_right_tabs
      layout = main_layout( center: make_detail_table, right: right)
      return show_base_template(title: Message[:customer_detail], body: Html.convert(layout))
    end

    private

    # １カラムに対してだけバリデーションを行う。
    def single_validation(result, target_key)
      unless target_key
        raise "target_key is empty: #{result}"
        return [] 
      end
      cmd_a = []
      if result[target_key.to_sym]
        cmd_a = show_validate_result(result)
      end
      if count_errors(result) == 0
        cmd_a.unshift({ reset_error: "#error-box-#{target_key}"})
      end
      comp_a = exec_completion(@form)
      cmd_a += comp_a if comp_a
      EzLog.debug("reset_error: #error-box-#{target_key}")
      EzLog.debug("single_validation: target_key=#{target_key}, result=#{result}, count=#{count_errors(result)}, cmd_a=#{cmd_a}")
      return cmd_a
    end

    # 全てのカラムに対してバリデーションを行う
    def full_validation(result)
      cmd_a = show_validate_result(result)
      cmd_a.unshift({ reset_error: ".error-box" })
      EzLog.debug("full_validation: full, cmd_a=#{cmd_a}")
      return cmd_a
    end

    # フォームの値の有効性チェックし、ajax用返信ハッシュを生成
    def show_validate_result(validate_result)
      cmd_a = []
      validate_result.each do |key, status|
        norm, err = status
        EzLog.debug("norm=#{norm}, err=#{err}")
        if norm
          cmd_a.push({ set_value: "input[name=#{key}]", value: norm })
        end
        if err
          msg = Message[err.to_sym]||err
          cmd_a.push({ set_error: "#error-box-#{key}", value: msg })
        end
      end
      return cmd_a
    end

    # validate_resultの中のエラーの数を数える
    def count_errors(validate_result)
      return validate_result.count {|k, a| a[1] }
    end

    # 詳細ページの表の生成
    def make_detail_table
      table = []
      array = @column_set.map do |column|
        next if column.no_view?
        edit_btn = nil
        if column.type.to_s == "textarea"
          view = Ht.pre(id: "#{@class_snake}-#{column.key}-view", child: column.view)
        else
          view = Ht.span(id: "#{@class_snake}-#{column.key}-view", child: column.view)
        end          
        table.push Ht.p(class: %w[hover-button-box], child: [ Ht.small(column.label), view, edit_btn ].compact)  
      end
      edit_btn = Ht.button(id: "#{@class_snake}-detail-edit-button", class: %w[btn], child: [ Ht.icon("edit"), Message[:edit_button_label] ], event: "on=click:url=#{make_base_url}/edit")
      table.push edit_btn
      return table
    end

    # 一覧ページ用のデータリスト生成
    def list_for_index(where: nil)
      where ||= {}
      where[:deleted_at] = nil
      return @column_set.dataset.where(where).order(@sort_key).all
    end

    def edit_cancel_button
      Ht.span(class: %w[btn red small waves-effect waves-light switch-button],  child: Ht.icon("clear"))
    end

    def make_create_button(event = nil)
      event ||= "on=click:command=redirect:url=#{make_base_url}/create"
      return Ht.button(class: %w[btn], child: [ Ht.icon("add"), Message[:create_button_label] ], event: event )
    end
  end
end
