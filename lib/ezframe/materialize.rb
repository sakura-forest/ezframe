# frozen_string_literal: true

class Materialize
  class << self
    attr_accessor :input_without_label

    def into_html_header
      <<~EOHEAD2
      <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
      <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">
      <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
      EOHEAD2
    end

    def into_html_header_local
      <<~EOHEAD
      <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
      <link rel="stylesheet" href="/css/materialize.min.css">
      <script src="/js/materialize.min.js"></script>
      EOHEAD
    end

    def into_bottom_of_body
      <<~EOBOT
      <script src="/js/htmlgen.js"></script>
      <script src="/js/common.js"></script>
      EOBOT
    end

    def convert(layout)
      return nil unless layout
      return layout if (layout.kind_of?(Hash) && layout[:final])
      new_layout = layout.clone
      # mylog("convert: new_layout: #{layout.inspect}")
      if layout.kind_of?(Array)
        new_layout = layout.map { |v| convert(v) }
      elsif layout.kind_of?(Hash)
        case layout[:tag].intern
        when :input, :select
          return layout if @input_without_label  
          new_layout = input(layout) if "hidden" != layout[:type]
          return new_layout
        when :checkbox
          new_layout = c = checkbox(layout)
          # mylog("checkbox: #{c}")
          return new_layout
        when :icon
          return icon(layout)
        when :form
          return new_layout = form(layout)
        when :table
          new_layout[:class] ||= []
          new_layout[:class].push("striped")
        end
        new_layout[:child] = convert(layout[:child]) if layout[:child]
      end
      return new_layout
    end

    def icon(layout)
      new_layout = layout.clone
      new_layout.add_class("material-icons")
      new_layout.update({ tag: "i", child: layout[:name] })
      new_layout.delete(:name)
      return new_layout
    end

    def form(layout)
      new_layout = layout.clone
      new_layout[:child] = convert(new_layout[:child])
      # new_layout = { tag: "div", class: ["container"], child: new_layout }
      return new_layout
    end

    def input(layout)
      layout[:name] ||= layout[:key]
      width_s = "s#{layout[:width_s] || 12}"
      layout.delete(:witdth_s)
      new_layout = div(add_sibling(layout, 
        { tag: "label", for: layout[:key], child: layout[:label], final: true }
      ), class: [ "input-field",  "col", width_s ])
      new_layout = div(new_layout, class: "row")
      return new_layout
    end

    def checkbox(layout)
      # return { tag: "label", for: layout[:name], child: [ { tag: "input", type: "checkbox", name: layout[:name] }, layout[:value] ] }
      { tag: "label", child: [ { tag: "input", type: "checkbox", name: layout[:name] }, { tag: "span", child: layout[:value] } ] }
    end

    def div(child, opts = {})
      { tag: "div", child: child }.update(opts)
    end

    def add_sibling(dest, elem) 
      if dest.is_a?(Array)
        dest.push(elem)
      else
        [ dest, elem ]
      end
    end
  end
end