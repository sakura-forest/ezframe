# frozen_string_literal: true

module Ezframe
  class Html
    class << self
      def wrap(opts = {})
        return "" if opts.nil? || opts.to_s.empty?
        return opts.to_html if opts.respond_to?(:to_html)
        return opts.to_s if opts.is_a?(String) || opts.is_a?(Symbol) || opts.is_a?(Integer) || opts.is_a?(Time)
        return opts.map { |args| wrap(args) }.join if opts.is_a?(Array)

        tag = opts[:tag]
        case tag
        when "select"
          return select(opts) if opts[:items]
        when "icon"
          tag = "i"
        end
        opt_s, child_s = join_attributes(opts)
        if child_s.length.positive?
          return "<#{tag} #{opt_s}>\n#{child_s}\n</#{tag}>\n"
        end
        "<#{tag} #{opt_s}/>"
      end

      def join_attributes(attrs)
        child_s = ""
        opt_a = attrs.map do |k, v|
          case k
          when :child
            child_s = wrap(v)
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

      def select(opts = {})
        attr = opts.clone
        items = attr[:items]
        if items.is_a?(Hash)
          option_a = opts[:items].map do |k, v|
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
          warn "unknown items: #{opts.inspect}"
        end
        attr[:tag] = "select"
        attr[:child] = option_a
        attr[:name] = attr[:key]
        attr[:final] = true
        attr.delete(:items)
        Html.wrap(attr)
      end
    end
  end
end
