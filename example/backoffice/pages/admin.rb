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
        [column.label, column.form]
      end
      matrix.push([{ tag: "input", type: "button", value: "送信", class: %w[btn], event: "on=click:cmd=inject:into=#center-panel:url=/admin/new:get_form=true" }])
      tb = Html::Table.new(matrix)
      layout = main_layout(left: sidenav, center: { tag: "form", method: "post", action: "/admin/new_submit", child: tb.to_layout })
      Materialize.input_without_label = true
      common_page(title: "新規顧客登録", body: Html.wrap(Materialize.convert(layout)))
    end

    def public_new_post
      # values = @request.POST
      @column_set.values = @json[:form]
      @column_set.save
      # mylog("new_submit: #{values.inspect}")
      # public_index_page
      make_index_table(@dataset.all)
    end

    def public_index_page
      data_a = @dataset.all
      htb = make_index_table(data_a)
      layout = main_layout(left: sidenav, center: { tag: "form", child: htb })
      common_page(title: "顧客情報", body: Html.wrap(Materialize.convert(layout)))
    end

    alias_method :public_default_page, :public_index_page

    def public_search_post
      mylog "public_search_post: #{@json.inspect}"
      word = @json[:form][:word]
      pattern = "%#{word}%"
      data_a = @dataset.where(Sequel.|(Sequel.like(:name_kana, pattern), Sequel.like(:name, pattern))).all
      make_index_table(data_a)
    end

    def public_detail_page
      mylog "pubilc_detail_page: #{@request.params.inspect}"
      data = @column_set.set_from_db(@id)
      return common_page(title: "no data", body: "no customer data: #{@id}") unless data
      # Materialize.convert(Html::Table.new(detail_table).to_layout)
      table = Html::Table.new(detail_table).to_layout
      common_page(title: "顧客情報", body: Html.wrap(Materialize.convert(main_layout(left: sidenav, center: table, right: right_tabs ))))
    end

    def public_detail_post
      mylog "public_detail_post: #{@request.params.inspect}: #{@json}"
      @id, @key = @json[:id], @json[:key]
      case @json[:cmd]
      when "update_value"
        update_value
      when "reset_value"
        reset_value
      else
        @column_set.set_from_db(@id)
        Materialize.input_without_label = true
        Materialize.convert(detail_edit_part(@column_set[@key])).to_json
      end
    end

    def right_tabs
      tabs = PageKit::Tab.base_layout([
        { tag: "a", href: "#alarm", child: "次回予定" },
        { tag: "a", href: "#order", child: "受注" },
        { tag: "a", href: "#talk", child: "会話" },
        { tag: "a", href: "#email", child: "Eメール" },
      ])
      a = %w[alarm order talk email].map { |k| { tag: "div", id: k, class: %w[col s12], event: "on=show:cmd=inject:into=##{k}:url=/admin/#{k}/index:customer=#{@id}", child: k } }
      a.unshift(tabs)
      a
    end

    def reset_value
      @id = @json[:id]
      @column_set.set_from_db(@id)
      column = @column_set[@json[:key]]
      Materialize.convert(detail_value_part(column))
    end
    
#    def public_form_page
#      mylog "public_form_page: params=#{@params.inspect}"
#      @column_set.set_from_db(@id)
#      column = @column_set[@key]
#      Materialize.input_without_label = true
#      Materialize.convert(detail_edit_part(column)).to_json
#    end

    private

    def update_value
      value = @json[:update_value]
      mylog("update_value: id=#{@id}, key=#{@key}, value=#{value}")
      column = @column_set.update(@id, @key, value)
      Materialize.convert(detail_value_part(column)).to_json
    end

    def detail_table
      @column_set.map do |column|
        column.attribute.delete(:hidden)  # Todo: remove this
        [column.label, detail_value_part(column)]
      end
    end

    def make_index_table(data_a)
      column_header = [:id, :name, :email, :zipcode, :prefecture]
      @column_set.each { |col| col.attribute.delete(:hidden) }
      a_element = Proc.new { |key, id, text|
        # mylog "proc executed"
        if key == :name
          { tag: "a", href: "/admin/detail?id=#{id}", child: text }
        else
          text
        end
      }
      table = PageKit::IndexTable.new(column_header: column_header, column_set: @column_set, add_checkbox: :id,
                                      decorate_column: a_element)
      table.make_table(data_a)
    end


    def detail_value_part(column)
      { tag: "span", id: "detail-#{column.key}", child: [{ tag: "span", child: column.view }, edit_button(column)].compact }
    end

    def edit_button(column)
      return nil if column.attribute[:no_edit]
      into = "#detail-#{column.key}"
      { tag: "a", key: column.key,
        event: "on=click:cmd=inject:into=#{into}:id=#{@id}:key=#{column.key}:value=#{column.value}",
        class: %w[btn btn-small circle waves-effect waves-light], child: { tag: "icon", name: "edit" } }
    end

    def detail_edit_part(column)
      # url = "/admin/finish?id=#{@id}&key=#{column.key}&value=#{column.value}"
      # reset_url = "/admin/value?id=#{@id}&key=#{column.key}&value=#{column.value}"
      into = "#detail-#{column.key}"
      { tag: "span", child: [column.form,
                            { tag: "span", class: %w[btn small teal waves-effect waves-light], event: "on=click:cmd=update_value:into=#{into}:id=#{@id}:key=#{column.key}:value=#{column.value}", child: { tag: "icon", name: "check" } },
                            { tag: "span", class: %w[btn small waves-effect waves-light], event: "on=click:cmd=reset_value:into=#{into}:id=#{@id}:key=#{column.key}:value=#{column.value}", child: { tag: "icon", name: "clear" } }] }
    end
  end
end
