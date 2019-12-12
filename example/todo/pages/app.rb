# frozen_string_literal: true

module Ezframe
  class App < PageBase
    def initialize(request, model)
      super(request, model)
      mylog "request=#{request.inspect}"
      @column_set = @model.column_sets[:todo]
      @dataset = @column_set.dataset
    end

    def public_index_page
      @params[:list]
      form = { tag: "form", child: [ 
        { tag: "div", class: "col s8", child: @column_set[:issue].form }, 
        { tag: "div", class: "col s4", child: { tag: "button", type: "button", class: %w[btn], child: "send",
        event: "on=click:cmd=open:goto=/app/index:get_form=true" } } ] }
      form = { tag: "div", class: "row", child: form } 
      # mylog(form.to_json)
      data_a = if [ 1, 2 ].include?(@params[:list].to_i)
        @dataset.where(status: @params[:list].to_i).all
      else
        @dataset.all
      end
      tb = Html::Table.new
      data_a.map do |data|
        @column_set.values = data
        delete_event = "on=click:cmd=open:goto=/app/index:delete=#{data[:id]}"
        checkbox = @column_set[:status].form
        checkbox[:checked] = "checked" if "2" == @column_set[:status].value.to_s
        checkbox[:event] = "on=change:cmd=open:goto=/app/index:change=#{data[:id]}:cur_stat=#{@column_set[:status].value}"
        # mylog "checkbox=#{checkbox}"
        tb.add_row([ 
          checkbox,
          [
            { tag: "span", child: @column_set[:issue].view }, 
            { tag: "button", type: "button", child: { tag: "icon", name: "clear" }, event: delete_event }
          ]])
      end
      # contents = multi_div([ %w[container], %w[row] ], [form, tb.make_table(data_a)])
      btns = [ [ 0, "all"], [1, "active"], [2, "completed"]].map do |a|
      # { tag: "a", href: event: "on=click:cmd=open:goto=/app/index:show=#{a[0]}", child: a[1] }
        { tag: "a", class: "btn", href: "/app/index?list=#{a[0]}", child: a[1] }
      end
      contents = multi_div([ %w[container], %w[row] ], [form, tb.to_hthash, btns])
      common_page(title: "Todos", body: Html.wrap(Materialize.convert(contents)))
    end

    def public_index_post
      mylog "public_index_post: #{@json}"
      if @json[:change]
        id = @json[:change]
        data = @dataset.where(id: id).first
        value = data[:status]
        value = case value.to_i
        when 1
          2
        when 2
          1
        end
        mylog "change: #{value}"
        @dataset.where(id: id).update(status: value)
      elsif @json[:delete]
        id = @json[:delete]
        @dataset.where(id: id).delete
      elsif @json[:form]
        @column_set.values = @json[:form]
        @column_set[:status].value = 1
        @column_set.save
      end
      { tag: "h1", child: "dummy" }
    end

    alias_method :public_default_page, :public_index_page
    alias_method :public_default_post, :public_index_post
  end
end
