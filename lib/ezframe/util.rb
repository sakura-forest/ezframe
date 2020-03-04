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

# https://github.com/cliftonsluss/recursively_symbolize_keys/blob/master/recursively_symbolize_keys.rb
class Hash
  def recursively_symbolize_keys
    h = Hash.new
    self.each do |k, v|
      if v.class == Hash
	      h[k.to_s.to_sym] = v.recursively_symbolize_keys
      else
	      h[k.to_s.to_sym] = v
      end
    end
    h
  end

  def add_class(klass)
    return unless klass
    if klass.is_a?(Array)
      klass.each {|k| add_class(k) }
      return
    end
    c = self[:class]
    if !c
      self[:class] = c = []
    elsif c.is_a?(String)
      a = [ c ]
      self[:class] = c = a
    end
    return if c.include?(klass)
    c.push(klass)
  end

  def remove_class(klass)
    c = self[:class]
    if c.is_a?(String)
      if klass == c
        self.delete(:class)
      end
    else
      c.delete(klass)
    end          
  end
end

class Array
  def recursively_symbolize_keys
    self.collect do |v|
      if v.kind_of?(Hash) || v.kind_of?(Array) 
        v.recursively_symbolize_keys
      else
        v  
      end  
    end    
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

def mylog(msg)
  if File.exist?("log")
    rack_env = ENV['RACK_ENV'] || "development"
    File.open("log/#{rack_env}.log", "a"){|f| f.puts "#{Time.now}:[#{$$}]:#{msg}" }
  end
end
