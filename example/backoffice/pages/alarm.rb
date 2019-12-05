# frozen_string_literal: true

module Ezframe
  class Admin
    class Alarm < PageBase
      include PageCommon

      def initialize(request, model)
        super(request, model)
        @column_set = @model.column_sets[:alarm]
        @dataset = @column_set.dataset
      end

      def public_index_post
        mylog "Alarm::public_index_post: #{@json}"
        customer_id = @json[:customer]
        # add_btn = { tag: "a", class: %w[btn-floating btn-small waves-effect waves-light teal], child: { tag: "icon", name: "add" } }
        data_a = @column_set.dataset.where(customer: customer_id).order(:scheduled_for).all
        form = %w[scheduled_for content].map { |key| @column_set[key].form }
        form.push({ tag: "button", type: "button", class: %w[btn], child: "登録",  event: "on=click:cmd=inject:into=#alarm_top:stage=2:url=/admin/alarm/new:customer=#{customer_id}:get_form=true" })
        new_form = { tag: "div", id: "alarm_top", child: { tag: "form", child: form } }
        list = data_a.map do |data|
          @column_set.clear
          @column_set.values = data
          PageKit::Card.base_layout(title: @column_set[:scheduled_for].view, content: @column_set[:content].view)
        end
        Materialize.input_without_label = nil
        return Materialize.convert([new_form, list])
      end

      def public_new_post
        @column_set.values = @json[:form]
        @column_set[:customer].value = @json[:customer]
        @column_set.save
        @column_set.clear
        public_index_post
      end

      private

      def make_index_json(data_a)
        column_header = [:scheduled_for, :content]
        @column_set.each { |col| col.attribute.delete(:hidden) }
        table = PageKit::IndexTable.new(column_header: column_header, column_set: @column_set, add_checkbox: :id,
                                        onclick_rows: Proc.new { |id| { event: "click", command: "inject", into: "#right-panel", url: "/alarm/new?customer=#{id}" } })
        #        onclick_rows: Proc.new {|id| { event: "click", command: "open", url: "/admin/detail?id=#{id}" } } )
        htb = table.make_table(data_a)
        # layout = main_layout(left: sidenav, center: { tag: "form", child: htb })
        return htb
      end
    end
  end
end
