# frozen_string_literal: true

module Ezframe
  class Materialize
    class << self
      def into_html_header

        css_a = Config[:extra_css_list].map {|file| "<link href=\"#{file}\" rel=\"stylesheet\">\n" }
        js_a = Config[:extra_js_list].map {|file| "<script src=\"#{file}\"></script>\n" }

        css_files = Dir["./asset/css/*.css"]||[]
        css_a += css_files.map do |file|
          file.gsub!("./asset", "")
          "<link href=\"#{file}\" rel=\"stylesheet\">\n"
        end
        js_files = Dir["./asset/js/*.js"]||[]
        js_a += js_files.map do |file|
          file.gsub!("./asset", "")
          "<script src=\"#{file}\"></script>\n"
        end
        (css_a+js_a).join
      end

      def into_bottom_of_body
        ""
      end

      def convert(ht_h)
        return nil unless ht_h
        return ht_h if (ht_h.kind_of?(Hash) && ht_h[:final])
        new_h = ht_h.clone
        if ht_h.kind_of?(Array)
          new_h = ht_h.map { |v| convert(v) }
        elsif ht_h.kind_of?(Hash)
          case ht_h[:tag].to_sym
          when :input, :select
            new_h = input(ht_h) if "hidden" != ht_h[:type]
            return new_h
          when :checkbox
            return checkbox(ht_h)
          when :radio
            return radio(ht_h)
          when :icon
            return icon(ht_h)
          when :form
            return new_h = form(ht_h)
          when :table
            new_h.add_class(%w[striped highlight])
          end
          new_h[:child] = convert(ht_h[:child]) if ht_h[:child]
        end
        return new_h
      end

      def icon(ht_h)
        new_h = ht_h.clone
        mylog "[warn] no name attribute for icon ht_h: #{ht_h.inspect}" unless new_h[:name]
        new_h.add_class("material-icons")
        new_h.update({ tag: "i", child: ht_h[:name] })
        new_h.delete(:name)
        return new_h
      end

      def form(ht_h)
        new_h = ht_h.clone
        new_h[:child] = convert(new_h[:child])
        return new_h
      end

      def input(ht_h)
        ht_h[:name] ||= ht_h[:key]
        width_s = "s#{ht_h[:width_s] || 12}"
        ht_h.delete(:witdth_s)
        label = Ht.label(for: ht_h[:key], child: ht_h[:label], final: true )
        cls = ["input-field", "col", width_s]
        new_h = Ht.div(class: cls, child: [ht_h, label])
        new_h = Ht.div(child: new_h, class: "row")
        return new_h
      end

      def checkbox(ht_h)
        ht_h[:tag] = "input"
        ht_h[:type] = "checkbox"
        Ht.label(child: [ht_h, { tag: "span", child: ht_h[:value] }])
      end

      def radio(ht_h)
        ht_h[:tag] = "input"
        ht_h[:type] = "radio"
        Ht.label(child: [ht_h, { tag: "span", child: ht_h[:label] }])
      end

      def add_sibling(dest, elem)
        if dest.is_a?(Array)
          dest.push(elem)
        else
          [dest, elem]
        end
      end
    end

    class Grid
      def initialize(matrix=nil)
        @matrix = matrix
        @matrix ||= [[]]
      end

      def add_row(row)
        
      end
    end
  end
end
