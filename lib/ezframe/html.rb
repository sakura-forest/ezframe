# frozen_string_literal: true

module Ezframe
  class Html
    class << self
      def convert(ht_h = {})
        ht_h = hook_for_convert(ht_h)
        return "" if ht_h.nil? || ht_h.to_s.empty?
        return ht_h.to_html if ht_h.respond_to?(:to_html)
        return ht_h.to_s if ht_h.is_a?(String) || ht_h.is_a?(Symbol) || ht_h.is_a?(Integer) || ht_h.is_a?(Time)
        return ht_h.map { |args| convert(args) }.join if ht_h.is_a?(Array)

        tag = ht_h[:tag]
        case tag
        when "textarea"
          textarea(ht_h)
        when "select"
          return select(ht_h) if ht_h[:item]
        when "icon"
          tag = "i"
        end
        tag = ht_h[:tag]
        error_box = ""
        #if %w[input select textarea].include?(tag)
        #  error_box = "<div id=\"error-box-#{ht_h[:name]}\" class=\"error-box hide\"></div>"
        #end
        opt_s, child_s = join_attribute(ht_h)
        if !child_s.strip.empty? || !%w[img input hr br meta].include?(tag)
          start_tag = [ht_h[:tag], opt_s].compact.join(" ").strip
          return "<#{start_tag}>#{child_s}</#{ht_h[:tag]}>"+error_box
        end
        tag_content = [ ht_h[:tag], opt_s ].compact.join(" ")
        return "<#{tag_content}/>"+error_box
      end

      # attributeの連結文字列化
      def join_attribute(attrs)
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

      def textarea(ht_h)
        value = ht_h[:value]
        if value
          ht_h[:child] = value
          ht_h.delete(:value)
        end
      end

      def select(ht_h = {})
        attr = ht_h.clone
        item = attr[:item]
        # puts "Html.select: #{item}"
        if item.is_a?(Hash)
          option_a = ht_h[:item].map do |k, v|
            h = { tag: "option", value: k }
            if v.is_a?(Array)
              v, selected = v
              h[:selected] = "selected" if selected
            end
            h[:child] = v
            # EzLog.info "select: hash: k=#{k}, v=#{v}, value=#{ht_h[:value]}"
            if ht_h[:value] && ht_h[:value].to_s == k.to_s
              h[:selected] = "selected"
            end
            h
          end
        elsif item.is_a?(Array)
          option_a = item.map do |v|
            h = { tag: "option", value: v[0], child: v[1] }
            if %w[selected default].include?(v[2])
              h[:selected] = "selected"
            end
            # EzLog.info "select: array: v=#{v}, value=#{ht_h[:value]}"
            if ht_h[:value] && ht_h[:value].to_s == v[0].to_s
              h[:selected] = "selected"
            end
            # puts h.inspect
            h
          end
        else
          warn "unknown item: #{ht_h.inspect}"
        end
        attr[:tag] = "select"
        attr[:child] = option_a
        attr[:name] ||= attr[:key]
        attr[:final] = true
        attr.delete(:item)
        Html.convert(attr)
      end

      def hook_for_convert(ht_h)
        return ht_h
      end
    end
  end
end
