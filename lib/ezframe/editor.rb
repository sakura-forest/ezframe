# frozen_string_literal: true

module Ezframe
  class DataEditor < PageBase

    def initialize(request=nil, model=nil)
      super(request, model)
      decide_target
      if model
        @column_set = @model.column_sets[@target]
        unless @column_set
          raise "[ERROR] no such column set: #{@target}"
        end
        @dataset = @column_set.dataset
      end
      if @parsed_body
        @event = @parsed_body[:event] || {}
        @target_id = @event[@target]
      end
      @auth = false
      init_vars
    end

    def init_vars
    end

    def decide_target
      @target = self.class.to_s
      if @target.index("::")
        @target = $1 if /::(\w+)$/ =~ @target
      end
      @target.downcase!
      @target = @target.to_sym
      return @target
    end

#    def public_login_get
#      flash_area = ""
#      mylog "public_login_get: #{@request}"
#      if @request
#        mylog "flash=#{@request.env['x-rack.flash']}"
#        flash_area = Ht.div(class: %w[teal], child: @request['env']['x-rack.flash'].error)
#      end
#      form = Ht.multi_div([ %w[container], %w[row]], 
#          Ht.form(class: "col s6 offset-s3", action: "/#{@target}/login", method: "post", child: [
#            Materialize.input(type: "text", name: "account", label: "User ID"),
#            Materialize.input(type: "password", name: "password", label: "Password"),
#            Ht.button(type: "submit", class: %w[btn], child: "login")
#          ]))
#      show_base_template(title: "Login", body: Html.convert(Materialize.convert([flash_area, form])))
#    end

#    def public_login_post
#      mylog "public_login_post: #{@params.inspect}, #{@parsed_body}"
#      warden.authenticate
#    public_index_get
#    end

    #--------------------------------------------------------------------------------------------------------
    # add new parts
    def public_create_get
      matrix = @column_set.map do |column|
        [column.label, column.form]
      end
      matrix.push([Ht.button(child: Message[:create_finish_button_label], class: %w[btn], event: "on=click:url=/#{@target}/create:with=form")])
      tb = Ht::Table.new(matrix)
      layout = main_layout(left: sidenav, center: Ht.form(child: tb.to_h))
      show_base_template(title: Message[:create_page_title], body: Html.convert(Materialize.convert(layout)))
    end

    def public_create_post
      @column_set.values = @event[:form]
      @column_set[:id].value = @target_id = @column_set.create
      { redirect: "/#{@target}/detail?id=#{@target_id}" }
    end

    #--------------------------------------------------------------------------------------------------------
    # index parts
    def public_index_get
      data_a = @dataset.all
      htb = make_index_table(data_a)
      layout = index_layout(left: sidenav, center: Ht.form(child: htb))
      show_base_template(title: Message[:index_page_title], body: Html.convert(Materialize.convert(layout)))
    end

    def make_index_table(data_a)
      column_header = [:id, :name, :email, :zipcode, :prefecture]
      @column_set.each { |col| col.attribute.delete(:hidden) }
      a_element = Proc.new { |key, id, text|
        # mylog "proc executed"
        if key == :name
          Ht.a(href: "/#{@target}/detail?id=#{id}", child: text)
        else
          text
        end
      }
      table = PageKit::IndexTable.new(column_header: column_header, column_set: @column_set, add_checkbox: :id,
                                      decorate_column: a_element)
      table.make_table(data_a)
    end

    alias_method :public_default_get, :public_index_get

    #--------------------------------------------------------------------------------------------------------
    # search parts
    def public_search_post
      mylog "public_search_post: #{@parsed_body.inspect}"
      word = @event[:form][:word]
      pattern = "%#{word}%"
      data_a = @dataset.where(Sequel.|(Sequel.like(:name_kana, pattern), Sequel.like(:name, pattern))).all
      make_index_table(data_a)
    end

    #--------------------------------------------------------------------------------------------------------
    # detail parts
    def public_detail_get
      mylog "pubilc_detail_get: #{@request.params.inspect}"
      @target_id ||= @request.params["id"]
      data = @column_set.set_from_db(@target_id)
      return show_base_template(title: "no data", body: "no customer data: #{@target_id}") unless data
      show_base_template(title: Message[:index_page_title], body: Html.convert(make_detail_get))
    end

    def make_detail_get
      layout = main_layout( left: sidenav, center: detail_table )
      @request.env['rack.session'][@target] = @target_id
      layout[:event] = "on=load:branch=set_global@target=#{@target_id}"
      Materialize.convert(layout)
    end

    def public_detail_post
      mylog "public_detail_post: #{@request.params.inspect}: #{@parsed_body}"
      if @parsed_body[:global]
        @target_id ||= @parsed_body[:global][@target]
      end
      @column_set.set_from_db(@target_id)
      case @event[:branch]
      when "update_value"
        update_value
      end
      { inject: "#center-panel", is_html: true, body: Html.convert(Materialize.convert(detail_table)) }
    end

    private

    def update_value
      form = @event[:form]
      @column_set.update(@target_id, form)
    end

    def detail_table
      row_a = @column_set.map do |column|
        # column.attribute.delete(:hidden)  # Todo: remove this
        Ht.tr(class: %w[hover-button-box], child: [ 
          Ht.td(child: column.label),
          Ht.td(child: Ht.div(class: %w[switch-box], child: [ detail_value_part(column), detail_form_part(column)].compact))
        ])
      end
      return Ht.table(child: row_a)
    end

    def detail_value_part(column)
      return Ht.span(class: %w[switch-element], child: [ Ht.span(child: column.view) , edit_button(column)])
    end

    def detail_form_part(column)
      return nil if column.attribute[:no_edit]
      form = column.form
      if (form)
        form = Ht.form(class: %w[switch-element hide], child: [ Ht.span(child: column.form) , edit_ok_button(column), edit_cancel_button ])
      end
      return form
    end

    def edit_button(column)
      return nil if column.attribute[:no_edit]
      return Ht.button(class: %w[btn-floating switch-button hover-button hide right], child: Ht.icon("edit"))
    end

    def edit_ok_button(column)
      return Ht.span(class: %w[btn small teal waves-effect waves-light], event: "on=click:branch=update_value:url=/#{@target}/detail:key=#{column.key}:with=form", child: Ht.icon("check"))
    end

    def edit_cancel_button
      Ht.span(class: %w[btn red small waves-effect waves-light switch-button],  child: Ht.icon("clear"))
    end
  end
end
