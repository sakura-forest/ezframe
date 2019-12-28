# frozen_string_literal: true

module Ezframe
  class TypeBase
    attr_accessor :attribute, :parent

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
      @attribute = attr if attr
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

    def view
      @value
    end

    def db_type
      nil
    end

    def db_value
      value
    end

    def form
      nil
    end

    def no_edit?
      return ((@attribute[:hidden] || @attribute[:no_edit]) && !@attribute[:force])
    end

    def no_view?
      return (@attribute[:hidden] && !@attribute[:force])
    end
  end

  class StringType < TypeBase
    def normalize
      @value.gsub!(/　/, ' ')
    end

    def form
      return nil if no_edit?
      h = { tag: 'input', type: 'text', name: @attribute[:key], key: @attribute[:key], label: @attribute[:label], value: @value||"" }
      h[:size] = @attribute[:size] if @attribute[:size]
      h
    end

    def db_type
      "string"
    end
  end

  class IntType < StringType
    def view
      return nil if no_view?
      Util.add_comma(@value.to_i)
    end

    def form
      return nil if no_edit?
      { tag: 'input', type: 'number', key: @attribute[:key], label: @attribute[:label], value: @value||"" }
    end

    def db_type
      "int"
    end
  end

  class ForeignType < IntType
    def view
      return nil if no_view?
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

    def form
      return nil
    end
  end

  class PasswordType < StringType
    def form
      return { tag: "input", type: "password", label: @attribute[:label], value: @value||""}
    end

    def db_value
      return value      
    end
  end

  class SelectType < TypeBase
    def form
      return nil if no_edit?
      return { tag: 'select', key: @attribute[:key], label: @attribute[:label], items: @attribute[:items], value: @value }
    end

    def db_type
      return "string"
    end
  end

  class CheckboxType < TypeBase
    def form
      return nil if no_edit?
      return { tag: "checkbox", key: @attribute[:key], name: @attribute[:key], value: parent[:id].value, label: @attribute[:label] }
    end

    def db_type
      return "int"
    end
  end

  class DateType < StringType
    def form
      h = super
      if h
#        h[:type] = 'date' 
        h[:type] = 'text' 
        h[:class] = "datepicker"
        h[:value] = value||""
      end
      return h
    end

    def db_type
      "datetime"
    end

    def value
      if @value.is_a?(Date) || @value.is_a?(Time)
        return "%d-%02d-%02d"%[@value.year, @value.mon, @value.mday]
      end
      return @value
    end

    def value=(v)
      if v.is_a?(String) && v.empty?
        return
      end
      super(v)
    end

    def view
      return nil if no_view?
      if @value.is_a?(Time)
        "#{@value.year}/#{@value.mon}/#{@value.mday}"
      else
        @value
      end
    end
  end

  class DatetimeType < DateType
  end

  class EmailType < StringType
    def form
      return nil if no_edit?
      h = super
      h[:type] = 'email' if h
      return h
    end
  end

  class TelephoneType < StringType
  end

  class JpnameType < StringType
  end

  class JpnameKanaType < StringType
    def set(val)
      val = val.tr('ァ-ン', 'ぁ-ん')
      super(val)
    end

    def validation
      unless /^[ぁ-ん ]+$/ =~ @value
        'ひらがなのみで入力してください。'
      end
    end
  end

  # 
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

    def form
      return nil if no_edit?
      h = super
      h[:items] = @pref_h
      return h
    end

    def view
      return @pref_h[@value.to_i]
    end
  end

  # Japanese Zipcode type column
  class ZipcodeType < StringType
    def view
      return nil if no_view?
      return "" unless @value
      return @value.to_s.gsub(/(\d{3})(\d{4})/) { "#{$1}-#{$2}" }
    end

    def db_type
      return "string"
    end
  end
end
