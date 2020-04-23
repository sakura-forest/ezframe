# frozen_string_literal: true

module Ezframe
  class DataEditor < PageBase
    # 一覧ページ生成
    def public_default_get
      id = get_id
      if id
        return show_detail_page
      else
        data_a = @dataset.all
        htb = make_index_table(data_a)
        layout = index_layout(center: Ht.form(child: htb))
        return show_base_template(title: Message[:index_page_title], body: Html.convert(layout))
      end
    end

    # 一覧テーブルの生成
    def make_index_table(data_a)
      # @column_set.each { |col| col.attribute.delete(:hidden) }
      idx_keys = @index_keys || @column_set.keys
      puts "idx_keys=#{idx_keys.inspect}"
      a_element = Proc.new { |key, id, text|
        if key.to_s.index("_name")
          Ht.a(href: "#{make_base_url(id)}", child: text)
        else
          text
        end
      }
      tr_a = data_a.map do |data|
        @column_set.clear
        @column_set.values = data
        line = idx_keys.map do |key| 
          view = @column_set[key].view
          Ht.td(Ht.a(href: "#{make_base_url(data[:id])}", child: view))
        end
        Ht.tr(line)
      end
      th_a = idx_keys.map {|key| Ht.th(@column_set[key.to_sym].label) }
      thead = Ht.thead(Ht.tr(th_a))
      tbody = Ht.tbody(tr_a)
      table_id = "enable_datatable_#{@class_snake}"
      return Ht.table(id: table_id, class: %w[enable_datatable], child: [ thead, tbody ], event: "on=load:command=enable_datatable:target=##{table_id}:size=10")
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
      unless @event[:form]
        { inject: "#center-panel", body: Ht.form(child: make_edit_form(:create)) }
      else
        # 値の保存
        @column_set.clear
        @column_set.values = @event[:form]
        @column_set[:id].value = id = @column_set.create
        return { redirect: make_base_url(id) }
      end
    end

    # データ編集受信
    def public_edit_post
      id = get_id
      unless @event[:form]
        data = @column_set.set_from_db(id)
        return show_message_page("no data", "data is not defined: #{id}") unless data
        { inject: "#center-panel", body: Html.convert(Ht.form(make_edit_form)) }
      else
        # 値を保存
        @column_set.update(id, @event[:form])
        { redirect: make_base_url(id) }
      end
    end

    # 編集フォームの生成
    def make_edit_form(command = :edit)
      @id = get_id
      table = []
      matrix = @column_set.map do |column|
        form = column.form
        table.push Ht.p([ Ht.small(column.label), form ]) if form
      end
      send_button = Ht.button(child: Message[:edit_finish_button_label], class: %w[btn], event: "on=click:url=#{make_base_url(@id)}/#{command}:with=form") 
      table.push(send_button)
      return Ht.table(Ht.tr(table))
    end

    #--------------------------------------------------------------------------------------------------------
    # 検索
    def public_search_post
      EzLog.info "public_search_post: #{@parsed_body.inspect}"
      sch_keys = @search_keys || @column_set.keys
      word = @params["word"]
      pattern = "%#{word}%"
      pattern_a = sch_keys.map {|key| Sequel.like(key, pattern) }
      data_a = @dataset.where(Sequel.|(*pattern_a)).all
      puts data_a.inspect
      layout = index_layout(center: make_index_table(data_a))
      show_base_template(title: Message[:search_result_page_title], body: Html.convert(layout))
    end

    # 詳細表示
    def show_detail_page
      EzLog.info "show_detail_page: #{@request.params.inspect}"
      id = get_id(@class_snake)
      unless @column_set.set_from_db(id)
        return show_message_page("no data", "data is not defined: #{id}")
      end
      layout = main_layout(center: make_detail_table)
      return show_base_template(title: Message[:detail_page_title], body: Html.convert(layout))
    end

    private

    # 詳細ページの表の生成
    def make_detail_table
      @id = get_id
      table = []
      array = @column_set.map do |column|
        edit_btn = nil
        if @column_edit_mode
          edit_btn = edit_button(column)
          edit_btn[:event] = "on=click:branch=edit_column:key=#{column.key}" if edit_btn
        end
        table.push(Ht.p(class: %w[hover-button-box], child: [ Ht.small(column.label), column.view, edit_btn ].compact))
      end
      unless @column_edit_mode
        edit_btn = Ht.button(class: %w[btn], child: [ Ht.icon("edit"), Message[:edit_button_label] ], event: "on=click:url=#{make_base_url(@id)}/edit")
        table.push(edit_btn)
      end
      return Ht.table(Ht.tr(table))
    end

    def edit_cancel_button
      Ht.span(class: %w[btn red small waves-effect waves-light switch-button],  child: Ht.icon("cancel"))
    end

    # URLからのIDの取得
    def get_id(class_name = nil)
      class_name ||= @class_snake
      params = @request.env['url_params']
      return nil unless params
      # EzLog.info "get_id: #{params.inspect}, #{class_name}"
      return params[class_name.to_sym]
    end

    # 値の更新
    def update_value
      form = @event[:form]
      @column_set.update(get_id, form)
    end

    # ラベル付きで1カラムのviewを表示
    def show_label_view(key)
      col = @column_set[key]
      Ht.span([Ht.small(col.label), col.view(force: true)])
    end

    # ラベル付きで1カラムのformを表示
    def show_label_edit(key)
      col = @column_set[key]
      Ht.span([Ht.small(col.label), col.form(force: true)])
    end

    # エラーページの表示
    def show_message_page(title, body)
      return show_base_template(title: title, body: Html.convert(body))
    end
  end
end
