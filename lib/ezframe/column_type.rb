# frozen_string_literal: true
require "date"

module Ezframe
  class TypeBase
    attr_accessor :attribute, :parent, :error

    def self.get_class(key)
      return nil unless key
      upper = Object.const_get("Ezframe")
      key_camel = "#{key}_type".to_camel
      # puts "get_class: #{key_camel}"
      # puts "const_get: #{upper.const_get(key_camel).inspect}"
      if upper.const_defined?(key_camel)
        return upper.const_get(key_camel)
      end
      return nil
    end

    def self.type_name
      if /::(\w*)Type/ =~ to_s
        return $1.to_s.to_snake
      end
      to_s.to_snake
    end

    def initialize(attr = nil)
      @attribute = attr || {}
    end

    def key
      @attribute[:key]
    end

    def label
      return nil if @attribute[:hidden]
      @attribute[:label]
    end

    def value(_situation = nil)
      @value
    end

    def value=(v)
      @value = v
    end

    def db_type
      nil
    end

    def db_value
      value
    end

    def form(opts = {})
      nil
    end

    def form_html(opts = {})
      form_h = form(opts)
      return nil unless form_h
      return Html.convert(form_h)
    end

    def view(opts = {})
      return nil if no_view?
      @value
    end

    def validate
      if !@value || @value.empty?
        if @attribute[:must]
          @error = "必須項目です。"
          return @error
        end
      end  
      return nil
    end

    def no_edit?
      return ((@attribute[:hidden] || @attribute[:no_edit]) && !@attribute[:force])
    end

    def no_view?
      return (@attribute[:hidden] && !@attribute[:force])
    end

    def multi_inputs?
      nil
    end
  end

  class TextType < TypeBase
    def normalize
      return unless @value
      @value = @value.dup.to_s
      @value.gsub!(/　/, " ")
      @value.gsub!(/\s+/, " ")
      @value.strip!
    end

    def value=(v)
      super(v)
      normalize
    end

    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      h = Ht.input(type: "text", name: self.key, label: @attribute[:label], value: @value || "")
      h[:size] = @attribute[:size] if @attribute[:size]
      h
    end

    def db_type
      "text"
    end
  end

  class IntType < TextType
    def view(opts = {})
      return nil if no_view? && !opts[:force]
      return @value.to_i.add_comma
    end

    def value=(v)
      if v.nil?
        @value = nil
        return
      end
      if v.is_a?(String)
        v = v.tr("０-９", "0-9").strip
      end
      @value = v.to_i
    end

    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      return Ht.input(type: "number", name: self.key, label: @attribute[:label], value: @value || "")
    end

    def db_type
      "int"
    end
  end

  class ForeignType < IntType
    def initialize(attr = nil)
      super
      @attribute[:no_edit] = true
    end

    def view(opts = {})
      return nil if no_view? && !opts[:force]
      dataset = @parent.db.dataset[self.type.inner]
      data = dataset.get(id: @value)
      return data[@attribute[:view]]
    end

    def form
      return nil
    end
  end

  class IdType < IntType
    def label
      return nil if no_view?
      return "ID"
    end

    def form(opts = {})
      return nil
    end
  end

  class PasswordType < TextType
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      return { tag: "input", type: "password", name: self.key, label: @attribute[:label], value: @value || "" }
    end

    def db_value
      return value
    end
  end

  class SelectType < TypeBase
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      # puts "selectType: #{@attribute[:items].inspect}"
      return { tag: "select", name: self.key, label: @attribute[:label], items: @attribute[:items], value: @value }
    end

    def db_type
      return "text"
    end

    def view(opts = {})
      return nil if no_view? && !opts[:force]
      items = @attribute[:items]
      return items[@value]
    end
  end

  class CheckboxType < TypeBase
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      return Ht.checkbox(name: self.key, value: parent[:id].value, label: @attribute[:label])
    end

    def db_type
      return "int"
    end
  end

  class DateType < TextType
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      h = super
      if h
        # h[:type] = 'date'
        h[:type] = "text"
        h[:class] = "datepicker"
        h[:value] = value || ""
      end
      return h
    end

    def db_type
      "date"
    end

    def value
      if @value.is_a?(Date) || @value.is_a?(Time)
        return "%d-%02d-%02d" % [@value.year, @value.mon, @value.mday]
      end
      return @value
    end

    def value=(v)
      if v.nil?
        @value = nil
        return
      end
      if v.is_a?(String)
        if v.strip.empty?
          @value = nil
          return
        end
        y, m, d = v.split(/[\-\/]/)
        @value = Date.new(y.to_i, m.to_i, d.to_i)
        return
      end
      if v.is_a?(Date) || v.is_a?(Time)
        @value = v
      else
        mylog "[WARN] illegal value for date type: #{v.inspect}"
      end
    end

    def view(opts = {})
      return nil if no_view? && !opts[:force]
      if @value.is_a?(Time) || @value.is_a?(Date)
        return "#{@value.year}/#{@value.mon}/#{@value.mday}"
      else
        return @value
      end
    end
  end

  class TimeType < TextType
  end

  class DatetimeType < DateType
    def db_type
      "timestamp"
    end
  end

  class BirthdayType < TextType
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      prefix = self.key
      now = Time.now
      year_list = []
      110.times do |y|
        year = now.year - y - 10
        year_list.push [year, "#{year}年 (#{Japanese.convert_wareki(year)})"]
      end

      year, mon, mday = parse_date(@value)
      mon_list = (1..12).map { |m| [m, "#{m}月"] }
      mon_list.unshift([0, "(月)"])
      mday_list = (1..31).map { |d| [d, "#{d}日"] }
      mday_list.unshift([0, "(日)"])
      return [Ht.select(name: "#{prefix}_year", items: year_list, value: year),
              Ht.select(name: "#{prefix}_mon", items: mon_list, value: mon),
              Ht.select(name: "#{prefix}_mday", items: mday_list, value: mday)]
    end

    def view(opts = {})
      return nil if no_view? && !opts[:force]
      return nil unless @value
      year, mon, mday = parse_date(@value)
      mon = "?" if mon == 0
      mday = "?" if mday == 0
      return "#{year}年 #{mon}月 #{mday}日"
    end

    def parse_date(date)
      if date && date =~ /(\d+)\-(\d+)\-(\d+)/
        return [ $1.to_i,$2.to_i,$3.to_i ]
      end
      return nil
    end

    def multi_inputs?
      true
    end

    def form_to_value(form)
      y, m, d = form["#{self.key}_year".to_sym], form["#{self.key}_mon".to_sym], form["#{self.key}_mday".to_sym]
      return "#{y.to_i}-#{m.to_i}-#{d.to_i}"
    end
  end

  class EmailType < TextType
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      h = super
      h[:type] = "email" if h
      return h
    end

    def normalize
      return unless @value
      @value = NKF.nkf('-w -Z4', @value)
    end

    def validate
      super
      return @error if @error
      if email_format?
        @error = "形式が正しくありません"
        return @error
      end
      return nil
    end

    def email_format?
      return nil unless @value
      return @value =~ /^[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
    end
  end

  class TelType < TextType
    def validate
      super
      return @error if @error
      unless /^0\d{9,10}$/ =~ @value
        @error = "形式が正しくありません"
        return @error
      end
    end
  end

  class JpnameType < TextType
  end

  class JpnameKanaType < TextType
    def normalize
      return unless @value
      super
      @value.tr!("ァ-ン", "ぁ-ん")
    end

    def validation
      unless /^[ぁ-ん ]+$/ =~ @value
        "ひらがなのみで入力してください。"
      end
    end
  end

  class PrefectureType < SelectType
    def initialize(attr)
      super(attr)
      @pref_a = %w[選択してください 北海道 青森県 岩手県 宮城県 秋田県 山形県 福島県
                   茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県
                   新潟県 富山県 石川県 福井県 山梨県 長野県 岐阜県 静岡県 愛知県
                   三重県 滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県
                   鳥取県 島根県 岡山県 広島県 山口県
                   徳島県 香川県 愛媛県 高知県
                   福岡県 佐賀県 長崎県 熊本県 大分県 宮崎県 鹿児島県 沖縄県]
      @pref_h = {}
      @pref_a.each_with_index { |p, i| @pref_h[i] = p }
    end

    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      h = super
      h[:items] = @pref_h
      return h
    end

    def view
      return nil if no_view? && !opts[:force]
      return @pref_h[@value.to_i]
    end
  end

  # Japanese Zipcode type column
  class ZipcodeType < TextType
    def view(opts = {})
      return nil if no_view? && !opts[:force]
      return "" unless @value
      return @value.to_s.gsub(/(\d{3})(\d{4})/) { "#{$1}-#{$2}" }
    end

    def db_type
      return "text"
    end
  end
end
