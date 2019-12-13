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

      button = Ht.button(type: "button", class: %w[btn], child: "send", event: "on=click:cmd=add_todo:with=form")
      form = Ht.form(class: %w[row], child: [ 
        Ht.div(class: "col s3 offset-s4", child: @column_set[:issue].form),
        Ht.div(class: "col s2", child: button)
      ])
      form = Ht.div(class: "container", child: form)

      data_a = if [ 1, 2 ].include?(@params[:list].to_i)
        @dataset.where(status: @params[:list].to_i).all
      else
        @dataset.all
      end
      # contents = multi_div([ %w[container], %w[row] ], [form, tb.make_table(data_a)])
      status_list = @column_set[:status].attribute[:items]
      radio_a = status_list.keys.map do |key|
        value = status_list[key]
        event = "on=change:cmd=change_filter:value=#{value}:with=self"
        Ht.radio(name: "status", value: key, label: value, event: event)
      end
#      btns = [ [ 0, "all"], [1, "active"], [2, "completed"]].map do |a|
#        Ht.a(class: "btn", href: "/app/index?list=#{a[0]}", child: a[1])
#      end
      Ht.div(class: %w[container], child: [ 
        Ht.div(class: %w[row], child: form),
        Ht.div(class: %w[row], child: tb.to_hash),
        Ht.div(class: %w[row], child: radio_a)
      ])
      common_page(title: "Todos", body: Html.convert(Materialize.convert(contents)))
    end

    def make_table
      tb = Ht::Table.new
      data_a.map do |data|
        @column_set.values = data
        delete_event = "on=click:cmd=delete:id=#{data[:id]}"
        checkbox = @column_set[:status].form
        checkbox[:checked] = "checked" if "2" == @column_set[:status].value.to_s
        checkbox[:event] = "on=change:cmd=change_status:id=#{data[:id]}:with=self:cur_stat=#{@column_set[:status].value}"
        # mylog "checkbox=#{checkbox}"
        tb.add_row([ 
          checkbox, [
            Ht.span(child: @column_set[:issue].view), 
            Ht.button(type: "button", child: Ht.icon(name: "clear"), event: delete_event )
          ]])
      end
      return tb
    end

    def public_index_post
      mylog "public_index_post: #{@json}"
      case @json[:cmd]
      when "add_todo"
        @column_set.values = @json[:form]
        @column_set[:status].value = 1
        @column_set.save
      when "delete_todo"
        id = @json[:delete]
        @dataset.where(id: id).delete
      when "change_status"
        new_stat = [0, 2, 1 ][@json[:cur_stat].to_i]
        @dataset.where(id: id).update(status: new_stat)
      when "change_filter"
        @session["filter"]=@json[:value]
      end
      { cmd: "inject", value: tb.to_hash }
    end

    alias_method :public_default_page, :public_index_page
    alias_method :public_default_post, :public_index_post
  end
end
