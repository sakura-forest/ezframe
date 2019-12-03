# frozen_string_literal: true

module Ezframe
  class Alarm < PageBase
    include PageCommon

    def initialize(request, model)
      super(request, model)
      @column_set = @model.column_sets[:alarm]
      @dataset = @column_set.dataset
    end

    def public_default_page
      customer = @params[:customer]
      add_btn = { tag: "a", class: %w[btn-floating btn-small waves-effect waves-light teal], child: { tag: "icon", name: "add" } }
      data_a = @column_set.dataset.where(customer: customer).order(:scheduled_for).all
      new_form = { tag: "form", child: %w[scheduled_for content].map {|key| @column_set[key].form} }
      Materialize.convert([ new_form, make_index_json(data_a) ])
    end

    def public_new_page

    end

    private

    def make_index_json(data_a)
      column_header = [ :scheduled_for, :content ]
      @column_set.each {|col| col.attribute.delete(:hidden)}
      table = PageKit::IndexTable.new(column_header: column_header, column_set: @column_set, add_checkbox: :id, 
        onclick_rows: Proc.new {|id| { event: "click", command: "inject", into: "#right-panel", url: "/alarm/new?customer=#{id}" } } )
#        onclick_rows: Proc.new {|id| { event: "click", command: "open", url: "/admin/detail?id=#{id}" } } )
      htb = table.make_table(data_a)
      # layout = main_layout(left: sidenav, center: { tag: "form", child: htb }) 
      return htb
    end

  end
end