# frozen_string_literal: true

module Ezframe
  module PageKit
    class IndexTable
      def initialize(attr = {})
        @attribute = attr
      end

      def make_table(row_a)
        column_set = @attribute[:column_set]
        table_a = row_a.map do |row_h|
          column_set.values = row_h
          id = column_set[:id].value
          value_a = (@attribute[:column_header]||[]).map do |key|
            col = column_set[key]
            unless col
              mylog "undefined key: #{key}"
              next
            end
            checkbox_key = @attribute[:add_checkbox]
            if checkbox_key && key == checkbox_key
              text = add_checkbox(col)
            else
              text = col.view
            end
            deco = @attribute[:decorate_column]
            if deco
              text = deco.call(key, id, text) 
              # mylog "deco: #{text}"
            end
            Ht.td(child: text)
          end
          tr = Ht.tr(child: value_a)
          if @attribute[:onclick_rows]
            tr[:id] = elem_id = "tr_#{id}"
          end
          tr
        end
        Ht.table(child: [make_header, table_a])
      end

      def add_checkbox(col)
        Ht.checkbox(name: "checkbox_#{col.key}_#{col.value}", value: col.value, label: col.view)
      end

      def make_header
        column_set = @attribute[:column_set]
        th_a = (@attribute[:column_header]||[]).map do |key|
          col = column_set[key]
          if col
            Ht.th(child: col.label)
          else
            nil
          end
        end
        if @attribute[:add_checkbox]
        end
        Ht.tr(child: th_a)
      end
    end
  end
end
