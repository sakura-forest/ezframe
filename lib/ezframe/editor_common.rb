module Ezframe
  module EditorCommon
    def get_id(class_name = nil)
      class_name ||= @class_snake
      params = @request.env['url_params']
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

    def show_message_page(title, body)
      return show_base_template(title: title, body: Html.convert(body))
    end
  end
end
