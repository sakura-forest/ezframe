class Integer
  def to_sym
    return self.to_s.to_sym
  end

  def add_comma
    return self.to_s.reverse.gsub(/(\d{3})(\d)/) { "#{$1},#{$2}" }.reverse
  end
end

class String
  def to_snake
    self.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').tr("-", "_").downcase
  end

  def to_camel
    self.split("_").map{|w| w[0] = w[0].upcase; w}.join
  end
end

class Object
  def deep_dup
    Marshal.load(Marshal.dump(self))
  end
end

class Time
  def to_date_key
    return "%d-%02d-%02d"%[ self.year, self.mon, self.mday ]
  end

  def wday_jp
    return %w[日 月 火 水 木 金 土 日][self.wday]
  end
end

# クラス名をsnake caseにする。
def class_to_snake(class_name)
  return nil unless class_name
  class_name = class_name.to_s
  if class_name.index("::")
    return class_name.split("::")[-1].to_snake.to_sym
  else
    return class_name.to_snake.to_sym
  end
end

# URLのオプションを解析
def parse_query_string(str)
  query_a = URI::decode_www_form(str)
  res_h = {}
  query_a.map { |a| res_h[a[0].to_sym] = a[1] }
  return res_h
end
