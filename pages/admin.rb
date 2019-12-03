# frozen_string_literal: true

module Ezframe  
  class Admin < PageBase
    include PageCommon
    def initialize(request, model)
      super(request, model)
      @column_set = @model.column_sets[:customer]
      # puts "Admin.init: #{@column_set.inspect}"
      @dataset = @column_set.dataset
    end

    def public_new_page
      matrix = @column_set.map do |column|
        [ column.label, column.form ]
      end
      matrix.push([{ tag: 'input', type: 'button', value: "送信", class: [ "submit-button"] }])
      tb = Html::Table.new(matrix)
      layout = main_layout(left: sidenav, center: { tag: "form", method: 'post', action: '/admin/new_submit', child: tb.to_layout })
      Materialize.input_without_label = true
      common_page(title: "新規顧客登録", body: Html.wrap(Materialize.convert(layout)))
    end

    def public_new_submit_page
      values = @request.POST
      @column_set.values = values
      @column_set.save
      mylog("new_submit: #{values.inspect}")
      public_index_page
    end

    def public_index_page
      data_a = @dataset.all
      make_index_page(data_a)
    end

    alias_method :public_default_page, :public_index_page

    def public_search_page
      data_a = @dataset.where(Sequel.like(:name, @request.params["word"])).all
      make_index_page(data_a)
    end

    def public_detail_page
      data = @column_set.set_from_db(@id)
      return common_page(title: "no data", body: "no customer data: #{@id}") unless data
      # Materialize.convert(Html::Table.new(index_table).to_layout).to_json
      table = Html::Table.new(index_table).to_layout
      common_page(title: "顧客情報", body: Html.wrap(Materialize.convert(main_layout(left: sidenav, center: table, right: right_tabs ))))
    end

    def right_tabs
      tabs = PageKit::Tab.base_layout([
        { tag: "a", href: "#alarm", child: "次回予定" },
        { tag: "a", href: "#order", child: "受注" },
        { tag: "a", href: "#talk", child: "会話" },
        { tag: "a", href: "#email", child: "Eメール" }
      ])
      a = %w[alarm order talk email].map {|k| { tag: "div", id: k, class: %w[col s12], event: "show", command: "inject", into: "##{k}", url: "/#{k}?customer=#{@id}", child: k } }
      a.unshift(tabs)
      a
    end

    def public_value_page
      @column_set.set_from_db(@id)
      column = @column_set[@key]
      Materialize.convert(detail_value_part(column)).to_json
    end

    def public_form_page
      mylog "public_form_page: params=#{@params.inspect}"
      @column_set.set_from_db(@id)
      column = @column_set[@key]
      Materialize.input_without_label = true
      Materialize.convert(detail_edit_part(column)).to_json
    end

    def public_finish_page
      value = @params[:update_value]
      mylog("public_finish_page: id=#{@id}, key=#{@key}, value=#{value}")
      column = @column_set.update(@id, @key, value)
      Materialize.convert(detail_value_part(column)).to_json
    end

    private

    def index_table
      @column_set.map do |column|
        column.attribute.delete(:hidden)  # Todo: remove this
        [ column.label, detail_value_part(column) ]
      end
    end

    def make_index_page(data_a)
      column_header = [ :id, :name, :email, :zipcode, :prefecture ]
      @column_set.each {|col| col.attribute.delete(:hidden)}
      table = PageKit::IndexTable.new(column_header: column_header, column_set: @column_set, add_checkbox: :id, 
#        onclick_rows: Proc.new {|id| { event: "click", command: "inject", into: "#right-panel", url: "/admin/detail?id=#{id}" } } )
        onclick_rows: Proc.new {|id| { event: "click", command: "open", url: "/admin/detail?id=#{id}" } } )
      htb = table.make_table(data_a)
      layout = main_layout(left: sidenav, center: { tag: "form", child: htb }) 
      common_page(title: "顧客情報", body: Html.wrap(Materialize.convert(layout)))
    end

    def detail_value_part(column)
      { tag: "span", id: "detail-#{column.key}", child: [ { tag: "span", child: column.view }, edit_button(column) ].compact }
    end

    def edit_button(column)
      return nil if column.attribute[:no_edit]
      into = "#detail-#{column.key}"
      { tag: "a", key: column.key, 
        event: "click", command: "inject", into: into, url: "/admin/form?id=#{@id}&key=#{column.key}&value=#{column.value}", 
        class: %w[btn btn-small circle  waves-effect waves-light], child:  { tag: "icon", name: "edit" } 
      }
    end

    def detail_edit_part(column)
      url = "/admin/finish?id=#{@id}&key=#{@key}&value=#{column.value}"
      reset_url = "/admin/value?id=#{@id}&key=#{@key}&value=#{column.value}"
      into = "#detail-#{@key}"
      { tag: "span", child: [ column.form, 
        { tag: "span", class: %w[btn small teal waves-effect waves-light], event: "click", command: "update_value", into: into, url: url, child: { tag: "icon", name: "check" } }, 
        { tag: "span", class: %w[btn small waves-effect waves-light], event: "click", command: "reset_value", into: into, url: reset_url, child: { tag: "icon", name: "clear" } } 
      ] }
    end
  end
end