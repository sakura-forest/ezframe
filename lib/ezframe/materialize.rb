# frozen_string_literal: true

module Ezframe
  class Materialize
    class << self
      def into_html_header
        <<~EOHEAD2
          <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
          <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">
          <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
        EOHEAD2
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
        new_h = hthash.clone
        if hthash.kind_of?(Array)
          new_h = hthash.map { |v| convert(v) }
        elsif hthash.kind_of?(Hash)
          case hthash[:tag].to_sym
          when :input, :select
            new_h = input(hthash) if "hidden" != hthash[:type]
            return new_h
          when :checkbox
            return checkbox(hthash)
          when :icon
            return icon(hthash)
          when :form
            return new_h = form(hthash)
          when :table
            new_h.add_class(%w[striped highlight])
          end
          new_h[:child] = convert(hthash[:child]) if hthash[:child]
        end
        return new_h
      end

      def icon(hthash)
        new_h = hthash.clone
        mylog "[warn] no name attribute for icon hthash: #{hthash.inspect}" unless new_h[:name]
        new_h.add_class("material-icons")
        new_h.update({ tag: "i", child: hthash[:name] })
        new_h.delete(:name)
        return new_h
      end

      def form(hthash)
        new_h = hthash.clone
        new_h[:child] = convert(new_h[:child])
        return new_h
      end

      def input(hthash)
        hthash[:name] ||= hthash[:key]
        width_s = "s#{hthash[:width_s] || 12}"
        hthash.delete(:witdth_s)
        label = Ht.label(for: hthash[:key], child: hthash[:label], final: true )
        cls = ["input-field", "col", width_s]
        new_h = Ht.div(class: cls, child: [hthash, label])
        new_h = Ht.div(child: new_h, class: "row")
        return new_h
      end

      def checkbox(hthash)
        hthash[:tag] = "input"
        hthash[:type] = "checkbox"
        Ht.label(child: [hthash, { tag: "span", child: hthash[:value] }])
      end

      def add_sibling(dest, elem)
        if dest.is_a?(Array)
          dest.push(elem)
        else
          [dest, elem]
        end
      end
    end
  end
end
