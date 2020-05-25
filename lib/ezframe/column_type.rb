# frozen_string_literal: true
require "date"

module Ezframe
  class TypeBase
    attr_accessor :attribute, :parent, :error

    def self.get_class(key)
      return nil unless key
      upper = Object.const_get("Ezframe")
      key_camel = "#{key}_type".to_camel
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

    def label(opts = {})
      return nil if @attribute[:hidden] && !opts[:force]
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
      if @attribute[:view_format]
        return use_view_format(@attribute[:view_format], @value)
      else
        @value
      end
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

    # 複数のinputを持っているか？
    def multi_inputs?
      nil
    end

    # フォーマットに従って表示する
    def use_view_format(format_a, val)
      return nil unless val
      if format_a.is_a?(String)
        return format_a % val
      else
        fmt_a = format_a.clone
        pattern = fmt_a.shift
        value_a = fmt_a.map {|key| val.send(key) }
        return pattern % value_a
      end
    end

    def make_error_box(name)
      Ht.div(id: "error-box-#{name}", class: %w[error-box hide], child: "")
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
      key = self.key
      key ="#{key}#{opts[:key_suffix]}" if opts[:key_suffix]
      h = Ht.input(type: "text", name: key, label: @attribute[:label], value: @value || "")
      h[:class] = @attribute[:class] if @attribute[:class]
      return [ h, make_error_box(key) ]
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
      key = self.key
      key ="#{key}#{opts[:key_suffix]}" if opts[:key_suffix]
      h = Ht.textarea(name: key, label: @attribute[:label], child: val)
      h[:class] = @attribute[:class] if @attribute[:class]
      return [ h, make_error_box(key) ]
    end
  end

  class IntType < TextType
    def view(opts = {})
      return nil if no_view? && !opts[:force]
      return nil unless @value
      return nil if @attribute[:no_view_if_zero] && @value.to_i == 0
      if @attribute[:view_format]
        return use_view_format(@attribute[:view_format], @value)
      else
        if @attribute[:add_comma]
          return @value.to_i.add_comma
        else
          return @value.to_s
        end
      end
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
      unless v.is_a?(Integer)  || v.is_a?(String)
        EzLog.debug("value must integer or string: key=#{self.key}, #{v}: class=#{v.class}")
        return
      end
      v = normalize(v)
      @value = v.to_i
    end

    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      key = self.key
      key ="#{key}#{opts[:key_suffix]}" if opts[:key_suffix]
      h = Ht.input(type: "number", name: key, label: @attribute[:label], value: @value || "")
      h[:class] = @attribute[:class] if @attribute[:class]
      return [ h, make_error_box(key) ]
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
    attr_accessor :db_data 

    def target_table
      table = @attribute[:table]
      return table if table
      return self.key
    end

    def view(opts = {})
      return nil if no_view? && !opts[:force]
      colkey = @attribute[:view_column]
      if @value && colkey
        data_h = DB::Cache[target_table.to_sym]
        data = data_h[@value.to_i]
        return nil unless data
        return data[colkey.to_sym]
      end
      return nil
    end

    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      view_key = @attribute[:menu_column] || @attribute[:view_column]
      data_h = DB::Cache[target_table.to_sym]
      menu_a = data_h.map do |id, data|
        [ data[:id], data[view_key&.to_sym] ]
      end
      key = self.key
      key ="#{key}#{opts[:key_suffix]}" if opts[:key_suffix]
      return [ Ht.select(name: key, class: %w[browser-default], item: menu_a, value: @value), make_error_box(key) ]
    end

    def db_type
      return "int"
    end

    def set_db_data
      @db_data = {}
      if @value
        @db_data = DB::Cache[target_table.to_sym][@value]
      end
    end
  end

  class IdType < IntType
    def form(opts = {})
      return nil
    end
  end

  class PasswordType < TextType
    def initialize(attr = nil)
      super(attr)
      @attribute[:no_view] = true
    end

    def encrypt_value(val)
      crypt = BCrypt::Password.create(val)
      return crypt.to_s
    end

    def value_equal?(value_from_db, new_value)
      crypt = BCrypt::Password.new(value_from_db)
      return crypt == new_value
    end

    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      key = self.key
      key ="#{key}#{opts[:key_suffix]}" if opts[:key_suffix]
      h = Ht.input(type: "password", name: key, label: @attribute[:label], value: "")
      h[:class] = @attribute[:class] if @attribute[:class]
      return  [ h, make_error_box ]
    end

    def db_value
      crypt = BCrypt::Password.create(@value)
      return crypt.to_s
    end
  end

  class SelectType < TypeBase
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      @items ||= @attribute[:item]
      h = Ht.select(class: %w[browser-default], name: self.key, label: @attribute[:label], item: @items, value: @value)
      h[:class] = @attribute[:class] if @attribute[:class]
      return [ h, make_error_box(self.key ) ]
    end

    def db_type
      return "text"
    end

    def view(opts = {})
      return nil if no_view? && !opts[:force]
      item = @attribute[:item]
      # EzLog.debug("select.view: @value=#{@value}, #{@value.class}, item=#{item}, result=#{item[@value]}")
      return nil unless @value
      return item[@value.to_s.to_sym]
    end

    def validate(val)
      return nil
    end
  end

  class CheckboxType < TypeBase
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      key = self.key
      key ="#{key}#{opts[:key_suffix]}" if opts[:key_suffix]
      h = Ht.checkbox(name: key, value: parent[:id].value, label: @attribute[:label])
      h[:class] = @attribute[:class] if @attribute[:class]
      return [ h, make_error_box(key) ]
    end

    def db_type
      return "text"
    end
  end

  class DateType < TextType
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      fm = super
      return nil unless fm
      h = fm[0]
      if h
        # h[:type] = 'date'
        h[:type] = "text"
        h[:value] = @value || ""
        h[:class] = [ "datepicker" ]
        h[:class].push(@attribute[:class]) if @attribute[:class]
      end
      return fm
    end

    def db_type
      return "date"
    end

    def value
      return nil if @value.nil? || (@value.is_a?(String) && @value.strip.empty?)
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
        EzLog.info "[WARN] illegal value for date type: #{v.inspect}"
      end
    end

    def view(opts = {})
      return nil if no_view? && !opts[:force]
      if @value.is_a?(Time) || @value.is_a?(Date)
        if @attribute[:view_format]
          return use_view_format(@attribute[:view_format], @value)
        else
          return "%d-%02d-%02d" % [@value.year, @value.mon, @value.mday]
        end
      else
        return @value
      end
    end
  end

  class TimeType < TextType
    def db_value
      return nil if @value.nil? || @value.strip.empty?
      return @value
    end
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
          @value = DateTime.parse(v)
        rescue => e
          EzLog.warn("date format error: #{self.key}=#{v}:#{e}")
          @value = nil
        end
        return
      end
      if v.is_a?(Date) || v.is_a?(Time) || v.is_a?(DateTime)
        @value = v
      else
        EzLog.info "[WARN] illegal value for date type: #{v.inspect}"
      end
    end

    def view(opts = {})
      return nil if no_view? && !opts[:force]
      if @value.is_a?(Time) || @value.is_a?(Date)
        if @attribute[:view_format]
          return use_view_format(@attribute[:view_format], @value)
        else
          return "%d/%02d/%02d %02d:%02d:%02d"%[@value.year, @value.mon, @value.mday, @value.hour, @value.min, @value.sec]
        end
      else
        return @value
      end
    end

    def form(opts = {})
      # EzLog.debug("DatetimeType: key=#{self.key}, opts=#{opts}")
      return nil if no_edit? && !opts[:force]
      fm = super
      return ni unless fm
      h = fm[0]
      if h
        # h[:type] = 'date'
        h[:type] = "text"
        h[:value] = @value || ""
        h[:class] = [ "datepicker" ]
        h[:class].push(@attribute[:class]) if @attribute[:class]
      end
      # EzLog.debug("DatetimeType: res=#{h}")
      return fm
    end

    def db_type
      "timestamp"
    end

    def value
      return nil if @value.nil? || (@value.is_a?(String) && @value.strip.empty?)
      return @value if @value.is_a?(Date) || @value.is_a?(Time)
      return DateTime.parse(@value) if @value.is_a?(String)
    end
  end

  class BirthdayType < TextType
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      now = Time.now
      year_list = []
      110.times do |y|
        year = now.year - y - 10
        year_list.push [year, "#{year}(#{Japanese.convert_wareki(year)})"]
      end
      year_list.unshift([ 0, "(年)" ])

      key = self.key
      key ="#{key}#{opts[:key_suffix]}" if opts[:key_suffix]

      year, mon, mday = parse_date(@value)
      mon_list = (1..12).map { |m| [m, "#{m}"] }
      mon_list.unshift([0, "(月)"])
      mday_list = (1..31).map { |d| [d, "#{d}"] }
      mday_list.unshift([0, "(日)"])
       [ Ht.div([Ht.select(name: "#{key}_year", class: %w[browser-default], item: year_list, value: year),
              Ht.small("年")]),
              Ht.select(name: "#{key}_mon", class: %w[browser-default], item: mon_list, value: mon),
              Ht.small("月"),
              Ht.select(name: "#{key}_mday", class: %w[browser-default], item: mday_list, value: mday),
              Ht.small("日"), 
              make_error_box(key)
      ]
    end

    def view(opts = {})
      return nil if no_view? && !opts[:force]
      return nil unless @value
      year, mon, mday = parse_date(@value)
      year_s = if year.to_i == 0 then "?" else "%d" % [year]; end
      mon_s = if mon.to_i == 0 then "?" else "%2d" % [mon]; end
      mday_s = if mday.to_i == 0 then "?" else "%2d" % [mday]; end
      return "#{year_s}<small>年</small>#{mon_s}<small>月</small>#{mday_s}<small>日</small>"
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

    def form_to_value(form, target_key: nil)
      key = target_key || self.key
      y, m, d = form["#{key}_year".to_sym], form["#{key}_mon".to_sym], form["#{key}_mday".to_sym]
      return "%d-%02d-%02d"%[y.to_i, m.to_i, d.to_i]
    end
  end

  class EmailType < TextType
    def form(opts = {})
      return nil if no_edit? && !opts[:force]
      fm = super
      return nil unless fm
      h = fm[0]
      h[:type] = "email"
      h[:class] = @attribute[:class] if @attribute[:class]
      return fm
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

  class UrlType < TextType
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
    attr_accessor :pref_h

    def initialize(attr = nil)
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
      fm = super
      return nil unless fm
      h = fm[0]
      h[:item] = @pref_h
      return fm
    end

    def view(opts = {})
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
