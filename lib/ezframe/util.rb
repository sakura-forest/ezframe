class Util
  def self.add_comma(value)
    value.to_s.reverse.gsub(/(\d{3})/) { "#{$1}," }.reverse
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
        h[k.to_sym] = v.recursively_symbolize_keys
      else
        h[k.to_sym] = v
      end
    end
    h
  end

  def add_class(klass)
    v = self[:class]
    if v.is_a?(Array)
      self[:class].push(klass)
    else
      self[:class] = [ v, klass ]
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

def multi_div(class_a, child)
  class_a.reverse.each do |klass|
    child = { tag: "div", class: klass, child: child }
  end
end

def mylog(msg)
  File.open("log/mylog.log", "a"){|f| f.puts "#{Time.now}:[#{$$}]:#{msg}" }
end