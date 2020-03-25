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
      @value = @attribute[:default]
    end

    def key
      @attribute[:key].to_sym
    end

    def label
      return nil if @attribute[:hidden]
      @attribute[:label]
    end

    def type
      @attribute[:type]
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

    def view(opts = {})
      return nil if no_view?
      @value
    end

    def normalize(val)
      return val
    end

    def validate(val)
      if !val || val.to_s.empty?
        if @attribute[:required] == "true"
          @error = "required"
          return @error
        end
      end  
      return nil
    end

    def no_edit?
      return ((@attribute[:hidden] || @attribute[:no_edit]) && !@attribute[:force])
    end

    def no_view?
      return (@attribute[:hidden] || @attribute[:no_view]) && !@attribute[:force]
    end

    def multi_inputs?
      nil
    end
  end

  class TextType < TypeBase
    def normalize(val)
      return nil unless val
      val = val.dup.to_s
      val.gsub!(/　/, " ")
      # val.gsub!(/\s+/, " ")
      val.strip!
      return val
    end

    def value=(val)
      @value = normalize(val)
    end

    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      h = Ht.input(type: "text", name: self.key, label: @attribute[:label], value: @value || "")
      h[:class] = @attribute[:class] if @attribute[:class]
      return h
    end

    def db_type
      return "text"
    end
  end

  class TextareaType < TextType
    def value=(val)
      @value = normalize(val)
      @value = val
    end

    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      val = @value
      h = Ht.textarea(name: self.key, label: @attribute[:label], child: val)
      h[:class] = @attribute[:class] if @attribute[:class]
      return h
    end
  end

  class IntType < TextType
    def view(opts = {})
      return nil if no_view? && !opts[:force]
      return @value.to_i.add_comma
    end

    def normalize(val)
      if val.is_a?(String)
        val = val.tr("０-９", "0-9").strip
      end
      return val
    end

    def value=(v)
      if v.nil?
        default = @attribute[:default]
        if default
          @value = default
        else
          @value = nil
        end
        return
      end

      if v.nil?
        @value = nil
        return
      end
      v = normalize(v)
      @value = v.to_i
    end

    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      h = Ht.input(type: "number", name: self.key, label: @attribute[:label], value: @value || "")
      h[:class] = @attribute[:class] if @attribute[:class]
      return h
    end

    def validate(val)
      return nil if !val || val.to_s.strip.empty?
      unless /^\d+$/ =~ val.to_s
        return :invalid_value
      end
      return nil
    end

    def db_type
      return "int"
    end
  end

  class ForeignType < IntType
    def initialize(attr = nil)
      super
      @attribute[:no_edit] = true
    end

    def target_table
      table = @attribute[:table]
      return table if table
      return self.key
    end

    def view(opts = {})
      return nil if no_view? && !opts[:force]
      return nil
    end

    def form
      return nil
    end

    def db_type
      return "int"
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
    def initialize(attr = nil)
      super(attr)
      @attribute[:no_view] = true
      @encrypt_on_set = true
    end

    def encrypt_value
      crypt = BCrypt::Password.create(@value)
      @value = crypt.to_s
    end

    def value_equal?(value_from_db, new_value)
      @crypt = Bcrypt::Password.new(value_from_db)
      return @crypt == new_value
    end

    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      h = { tag: "input", type: "password", name: self.key, label: @attribute[:label], value: "" }
      h[:class] = @attribute[:class] if @attribute[:class]
      return h
    end

    def db_value
      crypt = BCrypt::Password.create(@value)
      return crypt.to_s
    end
  end

  class SelectType < TypeBase
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      # puts "selectType: #{@attribute[:item].inspect}"
      h = { tag: "select", name: self.key, label: @attribute[:label], item: @attribute[:item], value: @value }
      h[:class] = @attribute[:class] if @attribute[:class]
      return h
    end

    def db_type
      return "text"
    end

    def view(opts = {})
      return nil if no_view? && !opts[:force]
      item = @attribute[:item]
      return item[@value]
    end

    def validate(val)
      return nil
    end
  end

  class CheckboxType < TypeBase
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      h = Ht.checkbox(name: self.key, value: parent[:id].value, label: @attribute[:label])
      h[:class] = @attribute[:class] if @attribute[:class]
      return h
    end

    def db_type
      return "text"
    end
  end

  class DateType < TextType
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      h = super
      if h
        # h[:type] = 'date'
        h[:type] = "text"
        h[:value] = @value || ""
        h[:class] = [ "datepicker" ]
        h[:class].push(@attribute[:class]) if @attribute[:class]
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
        default = @attribute[:default]
        if default
          @value = default
        else
          @value = nil
        end
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
        Logger.info "[WARN] illegal value for date type: #{v.inspect}"
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

  class DatetimeType < TextType
    def initialize(attr = nil)
      super(attr)
      @attribute[:class] = "datetimepicker"
    end

    def value=(v)
      if v.nil?
        default = @attribute[:default]
        if default
          @value = default
        else
          @value = nil
        end
        return
      end
      if v.is_a?(String)
        if v.strip.empty?
          @value = nil
          return
        end
        begin
          @value = Datetime.parse(v)
        rescue
          @value = nil
        end
        return
      end
      if v.is_a?(Date) || v.is_a?(Time) || v.is_a?(DateTime)
        @value = v
      else
        Logger.info "[WARN] illegal value for date type: #{v.inspect}"
      end
    end

    def view(opts = {})
      return nil if no_view? && !opts[:force]
      if @value.is_a?(Time) || @value.is_a?(DateTime)
        return "%d/%02d/%02d %02d:%02d:%02d"%[@value.year, @value.mon, @value.mday, @value.hour, @value.min, @value.sec]
      end
    end

    def form(opts = {})
      form = super(opts)
      return nil unless form
      form
    end

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
      year_list.unshift([ 0, "(年)" ])

      year, mon, mday = parse_date(@value)
      mon_list = (1..12).map { |m| [m, "#{m}月"] }
      mon_list.unshift([0, "(月)"])
      mday_list = (1..31).map { |d| [d, "#{d}日"] }
      mday_list.unshift([0, "(日)"])
      return [Ht.select(name: "#{prefix}_year", item: year_list, value: year),
              Ht.select(name: "#{prefix}_mon", item: mon_list, value: mon),
              Ht.select(name: "#{prefix}_mday", item: mday_list, value: mday)]
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
      h[:class] = @attribute[:class] if @attribute[:class]
      return h
    end

    def normalize(val)
      return nil unless val
      return NKF.nkf('-w -Z4', val)
    end

    def validate(val)
      super(val)
      return @error if @error
      return nil if !val || val.strip.empty?
      unless email_format?(val)
        @error = :invalid_value
        return @error
      end
      return nil
    end

    def email_format?(val)
      return val.to_s =~ /^[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
    end
  end

  class TelType < TextType
    def normalize(val)
      return nil unless val
      val = super(val)
      val = val.tr("０-９", "0-9")
      # val = val.gsub(/\D+/, "")
      return val
    end

    def validate(val)
      super(val)
      return @error if @error
      return nil if !val || val.strip.empty?
      unless /^0\d{9,10}$/ =~ val.to_s
        @error = :invalid_value
        return @error
      end
      return nil
    end
  end

  class JpnameType < TextType
  end

  class KatakanaType < TextType
    def normalize(val)
      val = super(val)
      return val.tr("ァ-ン", "ぁ-ん")
    end

    def validate(val)
      super(val)
      return @error if @error
      return nil if !val || val.strip.empty?
      unless /^[ぁ-ん ]+$/ =~ val.to_s
        @error = :hiragana_only
        return @error
      end
      return nil
    end
  end

  class KatakanaType < TextType
    def normalize(val)
      return nil unless val
      val = super(val)
      return val.tr("ぁ-ん", "ァ-ン")
    end

    def validate(val)
      super(val)
      return @error if @error
      return nil if !val || val.strip.empty?
      unless /^[ァ-ン ]+$/ =~ val
        @error = :katakana_only
        return @error
      end
      return nil
    end
  end

  class PrefectureType < SelectType
    def initialize(attr)
      super(attr)
      @pref_a = %w[() 北海道 青森県 岩手県 宮城県 秋田県 山形県 福島県
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
      h[:item] = @pref_h
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

    def normalize(val)
      val = super(val)
      return nil if !val || val.strip.empty?
      val = val.tr("０-９", "0-9")
      return val
    end

    def validate(val)
      super(val)
      return @error if @error
      return nil if !val || val.to_s.strip.empty?

      unless /^\d{7}$/ =~ val.to_s
        @error = :invalid_value
        return @error
      end
      return nil
    end
  end
end
