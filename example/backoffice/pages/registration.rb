# frozen_string_literal: true

module Ezframe
  class Registration < PageBase
    def initialize(request, model)
      super(request, model)
      @column_set = @model.column_sets[:customer]
    end  
    
    def public_default_page
      fm = @column_set.form
      fm.push(tag: 'button', type: 'button', class: ['submit-button'], child: '送信')
      common_page(title: '登録フォーム', 
        body: Html.wrap(Materialize.convert(tag: 'form', method: 'post', action: '/registration/confirm', child: fm)))
    end

    def public_confirm_page
      @column_set.values = @request.POST

      table = Html::Table.new(@column_set.get_matrix(%i[label view]))
      table.add_row([{ tag: 'button', type: 'button', class: ['submit-button'], child: '送信' }])
      form = { tag: 'form', method: 'post', action: '/registration/thanks', id: 'confirm-form', child: [table.to_layout, @column_set.hidden_form] }
      common_page(title: '確認', 
                  body: Html.wrap(tag: 'div', class: 'container', child: Materialize.convert(form)))
    end

    def public_thanks_page
      @column_set.values = post = @request.POST
      # p "post=#{post.inspect}"
      @model.save(@column_set)
      # p "thanks_page=#{@column_set.values.inspect}"
      common_page(title: 'ありがとうございました', body: 'ご登録ありがとうございました')
    end
  end
end