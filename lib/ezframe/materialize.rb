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

    def convert(hthash)
      return nil unless hthash
      return hthash if (hthash.kind_of?(Hash) && hthash[:final])
      new_hthash = hthash.clone
      # mylog("convert: new_hthash: #{hthash.inspect}")
      if hthash.kind_of?(Array)
        new_hthash = hthash.map { |v| convert(v) }
      elsif hthash.kind_of?(Hash)
        case hthash[:tag].to_sym
        when :input, :select
          return hthash if @input_without_label  
          new_hthash = input(hthash) if "hidden" != hthash[:type]
          return new_hthash
        when :checkbox
          new_hthash = c = checkbox(hthash)
          # mylog("checkbox: #{c}")
          return new_hthash
        when :icon
          return icon(hthash)
        when :form
          return new_hthash = form(hthash)
        when :table
          new_hthash[:class] ||= []
          new_hthash[:class].push("striped")
          new_hthash[:class].push("highlight")
        end
        new_hthash[:child] = convert(hthash[:child]) if hthash[:child]
      end
      return new_hthash
    end

    def icon(hthash)
      new_hthash = hthash.clone
      new_hthash.add_class("material-icons")
      new_hthash.update({ tag: "i", child: hthash[:name] })
      new_hthash.delete(:name)
      return new_hthash
    end

    def form(hthash)
      new_hthash = hthash.clone
      new_hthash[:child] = convert(new_hthash[:child])
      # new_hthash = { tag: "div", class: ["container"], child: new_hthash }
      return new_hthash
    end

    def input(hthash)
      hthash[:name] ||= hthash[:key]
      width_s = "s#{hthash[:width_s] || 12}"
      hthash.delete(:witdth_s)
      new_hthash = div(add_sibling(hthash, 
        { tag: "label", for: hthash[:key], child: hthash[:label], final: true }
      ), class: [ "input-field",  "col", width_s ])
      new_hthash = div(new_hthash, class: "row")
      return new_hthash
    end

    def checkbox(hthash)
      hthash[:tag]="input"
      hthash[:type]="checkbox"
      { tag: "label", child: [ hthash, { tag: "span", child: hthash[:value] } ] }
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