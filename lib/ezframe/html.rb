# frozen_string_literal: true

module Ezframe
  class Html
    class << self
      WrapTags = %w[html head body title h1 h2 h3 h4 h5 h6 p div span i strong ul ol li table thead tbody tr th td a 
        form button select option textarea label fieldset 
        nav aside footer small pre iframe checkbox radio script]
      SingleTags = %w[br hr meta img input ]

      def convert(ht_h = {})
        ht_h = ht_h.to_ht if ht_h.respond_to?(:to_ht)
        ht_h = hook_for_convert(ht_h)
        return "" if ht_h.nil? || ht_h.to_s.empty?
        return ht_h.to_html if ht_h.respond_to?(:to_html)
        return ht_h.to_s if ht_h.is_a?(String) || ht_h.is_a?(Symbol) || ht_h.is_a?(Integer) || ht_h.is_a?(Time)
        return ht_h.map { |args| convert(args) }.join if ht_h.is_a?(Array)

        tag = ht_h[:tag]
        case tag
        when :textarea
          textarea(ht_h)
        when :select
          return select(ht_h) if ht_h[:item]
        when :icon
          tag = "i"
        when :button
          ht_h[:type] ||= "button"
        end
        tag = ht_h[:tag]
        join_info = join_attribute(ht_h)
        start_tag = [ht_h[:tag], join_info[:attr]].compact.join(" ").strip
        if ht_h[:wrap] || WrapTags.include?(tag.to_s)
          return "#{join_info[:before]}<#{start_tag}>#{join_info[:child]}</#{ht_h[:tag]}>#{join_info[:after]}"
        end
        return "#{join_info[:before]}<#{start_tag}/>#{join_info[:after]}"
      end

      # attributeの連結文字列化
      def join_attribute(attrs)
        child_s = ""
        before = ""
        after = ""
        opt_a = attrs.map do |k, v|
          case k
          when :before
            before = convert(v)
            next
          when :after
            after = convert(v)
            next
          when :wrap
            nil
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
        { attr: opt_a.compact.join(" "), before: before, after: after, child: child_s }
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
            h = Ht.option(value: k)
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
            h = Ht.option(value: v[0], child: v[1])
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
        attr[:wrap] = true
        attr.delete(:item)
        Html.convert(attr)
      end

      def hook_for_convert(ht_h)
        return ht_h
      end
    end
  end
end
