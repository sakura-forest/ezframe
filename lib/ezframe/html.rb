# frozen_string_literal: true

module Ezframe
  class Html
    class << self
      def convert(ht_h = {})
        return "" if ht_h.nil? || ht_h.to_s.empty?
        return ht_h.to_html if ht_h.respond_to?(:to_html)
        return ht_h.to_s if ht_h.is_a?(String) || ht_h.is_a?(Symbol) || ht_h.is_a?(Integer) || ht_h.is_a?(Time)
        return ht_h.map { |args| convert(args) }.join if ht_h.is_a?(Array)

        tag = ht_h[:tag]
        case tag
        when "input"
          input(ht_h)
        when "select"
          return select(ht_h) if ht_h[:items]
        when "icon"
          tag = "i"
        end
        opt_s, child_s = join_attributes(ht_h)
        if child_s.length >= 0
          return "<#{tag} #{opt_s}>\n#{child_s}\n</#{tag}>\n"
        end
        "<#{tag} #{opt_s}/>"
      end

      def join_attributes(attrs)
        child_s = ""
        opt_a = attrs.map do |k, v|
          case k
          when :child
            child_s = convert(v)
            next
          when :tag, :final
            next
          when :key
            "name=\"#{v}\"" if attrs[:tag].to_sym == :input
            next
          else
            if v.is_a?(Array)
              "#{k}=\"#{v.join(" ")}\""
            elsif v.nil?
              nil
            else
              "#{k}=\"#{v}\""
            end
          end
        end
        [opt_a.compact.join(" "), child_s]
      end

      def input(ht_h)
        size = ht_h[:size]
        if size && (size.index("x") || size.index("*"))
          if /(\d+)\s*[x\*]\s*(\d+)/ =~ size
            ht_h[:cols], ht_h[:rows] = $1, $2
          end
          ht_h[:tag] = "textarea"
          ht_h[:child] = ht_h[:value]
          ht_h.delete(:value)
        end
      end

      def select(ht_h = {})
        attr = ht_h.clone
        items = attr[:items]
        if items.is_a?(Hash)
          option_a = ht_h[:items].map do |k, v|
            h = { tag: "option", value: k }
            if v.is_a?(Array)
              v, selected = v
              h[:selected] = "selected" if selected
            end
            h[:child] = v
            h
          end
        elsif items.is_a?(Array)
          option_a = items.map do |v|
            h = { tag: "option", value: v[0], child: v[1] }
            if %w[selected default].include?(v[2])
              h[:selected] = "selected"
            end
            h
          end
        else
          warn "unknown items: #{ht_h.inspect}"
        end
        attr[:tag] = "select"
        attr[:child] = option_a
        attr[:name] = attr[:key]
        attr[:final] = true
        attr.delete(:items)
        Html.convert(attr)
      end
    end
  end
end
