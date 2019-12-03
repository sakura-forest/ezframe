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
          value_a = @attribute[:column_header].map do |key|
            col = column_set[key]
            checkbox_key = @attribute[:add_checkbox]
            if checkbox_key && key == checkbox_key
              td = { tag: "td", child: add_checkbox(col) }
              p td
            else
              td = { tag: "td", child: col.view }
            end
            td
          end
          tr = { tag: "tr", child: value_a }
          id = column_set[:id].value
          if @attribute[:onclick_rows]
            tr[:id] = elem_id = "tr_#{id}"
            tr.update(@attribute[:onclick_rows].call(id))
          end
          tr
        end
        { tag: "table", child: [ make_header, table_a ] }
      end  

      def add_checkbox(col)
        { tag: "checkbox", name: "checkbox_#{col.key}_#{col.value}", value: col.value, label: col.view }
      end
    
      def make_header
        column_set = @attribute[:column_set]
        th_a = @attribute[:column_header].map do |key| 
          col = column_set[key]
          if col
            { tag: "th", child: col.label } 
          else
            nil
          end
        end
        if @attribute[:add_checkbox]
        end
        { tag: "tr", child: th_a }
      end
    end

    class Tab
      def self.base_layout(link_list)
        size = 12 / link_list.length
        tabs = link_list.map do |link|
          { tag: "li", class: [ "tab", "s#{size}" ], child: link }
        end
        ul = { tag: "ul", class: %w[tabs], child: tabs } 
        div = { tag: "div", class: %w[row s12], child: ul }
        { tag: "div", class: %w[row], child: div }
      end
    end
  end
end