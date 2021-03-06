module Ezframe
  module EditorCommon
    def get_id(class_name = nil)
      class_name ||= @class_snake
      params = @controller.route_params
      EzLog.debug "get_id: #{params.inspect}, #{class_name}"
      return nil unless params
      return params[class_name.to_sym]
    end

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

    def make_form(url, child)
      return Ht.form(ezload: "command=set_validation:validate_url=#{url}", child: child)
    end

    #  新規登録ボタンの生成
    def make_create_button(event = nil)
      event ||= "on=click:command=post:url=#{make_base_url(@id)}/create"
      return Ht.button(id: "#{@class_snake}-create-button", class: %[btn], child: [Ht.icon("add"), Message[:create_button_label]], ezevent: event)
    end

    # 編集ボタンの生成
    def make_edit_button(event = nil)
      event ||= "on=click:command=post:url=#{make_base_url(@id)}/edit"
      return Ht.button(class: %w[btn], ezevent: event, child: [ Ht.icon("edit"), Message[:edit_button_label]])    
    end

    # 削除ボタンの生成
    def make_delete_button(event = nil)
      event ||= "on=click:command=post:url=#{make_base_url(@id)}/delete"
      return Ht.button(class: %w[btn right red], ezevent: event, child: [Ht.icon("delete"), Message[:delete_button_label]])
    end

    # キャンセルボタンの生成
    def make_cancel_button(event = nil)
      event ||= "on=click:command=post:url=#{make_base_url(@id)}/detail:cancel=true:with=form"
      return [ "button.btn.btn-danger:ezevent=[#{event}]", [ "i.fa.fa-times", "text:#{Message[:cancel_button_label]}" ]]
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

    # エラーメッセージだけを表示するページを生成
    def show_message_page(title, body)
      content = PageMaker::PageContent.new
      layout = Layout.new
      # layout.embed[:page_title] = title
      layout.embed[:body] = Html.convert(body)
      content.body = layout
      content.title = title
      return layout
    end
  end
end
