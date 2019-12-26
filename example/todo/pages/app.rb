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

      # add todo form
      button = Ht.button(type: "button", class: %w[btn], child: "send", event: "on=click:cmd=add_todo:with=form")
      form = Ht.form(class: %w[row], id: "add-form", child: [ 
        Ht.div(class: "col s3 offset-s4", child: @column_set[:issue].form),
        Ht.div(class: "col s2", child: button)
      ])
      form = Ht.div(class: "container", child: form)

      # radio buttons for filter
      status_list = @column_set[:status].attribute[:items]
      mylog("status_list=#{status_list.inspect}")
      radio_a = status_list.keys.map do |key|
        value = status_list[key]
        event = "on=change:cmd=change_filter:value=#{value}:with=self"
        Ht.radio(name: "status", value: key, label: value, event: event)
      end
      event = "on=change:cmd=change_filter:value=0:with=self"
      radio_a.unshift(Ht.radio(name: "status", value: "0", label: "All", event: event, checked: "checked"))

      # join all
      tb = make_table.to_h
      contents = Ht.div(class: %w[container], child: [ 
        Ht.div(class: %w[row], child: form),
        Ht.div(class: %w[row], id: "filter-buttons", child: radio_a),
        Ht.div(class: %w[row], id: "main-table", child: tb.to_h)
      ])
      common_page(title: "Todos", body: Html.convert(Materialize.convert(contents)))
    end

    def make_table
      data_a = @dataset.all
      tb = Ht::Table.new
      tb.header = [ "ID", "issue" ]
      data_a.map do |data|
        @column_set.values = data
        delete_event = "on=click:cmd=delete_todo:id=#{data[:id]}"
        checkbox = Ht.checkbox(name: "status", value: data[:id])  # @column_set[:status].form
        checkbox[:checked] = "checked" if "2" == @column_set[:status].value.to_s
        checkbox[:event] = "on=change:cmd=change_status:id=#{data[:id]}:cur_stat=#{@column_set[:status].value}"
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
      opts={}
      event = @json[:event]
      case event[:cmd]
      when "add_todo"
        mylog "add_todo"
        @column_set.values = event[:form]
        @column_set[:status].value = 1
        @column_set.save
        opts[:reset] = "#add-form"
      when "delete_todo"
        id = event[:id]
        @dataset.where(id: id).delete
      when "change_status"
        new_stat = [ 0, 2, 1 ][event[:cur_stat].to_i]
        id = event[:id]
        @dataset.where(id: id).update(status: new_stat)
      when "change_filter"
        @session["filter"] = event[:value]
      end
      return_value = { inject: "#main-table", body: Materialize.convert(make_table.to_h) }
      return_value.update(opts)
      return return_value
    end

    alias_method :public_default_page, :public_index_page
    alias_method :public_default_post, :public_index_post
  end
end
