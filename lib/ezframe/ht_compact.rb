module Ezframe
  class Ht
    class << self
#    attr_accessor :value_a

#    def initialize(*arg)
#      @value_a = []
#      add(arg)
#    end

#    def add(arg)
#      return unless arg
#      if arg.is_a?(Array)
#        @value_a += arg
#      elsif arg.is_a?(HtCompact)
#        @value_a += arg.value_a
#      elsif arg.is_a?(String) || arg.is_a?(Ht)
#        @value_a.push(arg)
#      else
#        EzLog.error("HtCompact: illegal value: class=#{arg.class}:arg=#{arg}")
#      end
#    end

#    def to_ht
#      return self.convert(@value_a)
#    end

      def compact(*arg)
        arg = arg[0] if arg.is_a?(Array) && arg.length == 1
        return nil if arg.nil?
        if arg.is_a?(String)
          res = parse_ht_string(arg)
          puts "compact: is_a_string: res=#{res}"
          # res = res[0] if res.is_a?(Array) && res.length == 1
          return res
        elsif arg.is_a?(Hash) || arg.is_a?(Ht)
          return arg
        elsif arg.respond_to?(:to_ht)
          return arg.to_ht
        elsif arg.is_a?(Array)
          return _array_to_ht(arg)
        else
          raise "Ht.convert: illegal value: type=#{arg.class}, value=#{arg}"
        end
      end

      def _array_to_ht(array)
        return nil unless array
        res_a = []
        pointer = 0
        while pointer < array.length
          val = array[pointer]
          if val.respond_to?(:to_ht)
            # $stderr.puts "_arrray_to_ht: to_ht: #{val}"
            res = val.to_ht
            # $stderr.puts("to_ht: #{res}")
            res_a.push(res)
            pointer += 1
            next
          elsif val.is_a?(Hash)
            res_a.push(val)
            pointer += 1
            next
          elsif val.is_a?(String)
            ht = parse_ht_string(val)
            next_val = array[pointer + 1]
            if next_val.is_a?(Array)
              Ht.connect_child(ht, _array_to_ht(next_val))
              pointer += 1
            else
            end
            res_a.push(ht)
          elsif val.is_a?(Array)
            res_a.push(Ht.div(_array_to_ht(val)))
          end
          pointer += 1
        end
        return res_a
      end

      def parse_ht_string(str)
        debug = nil
        # debug = true if str.index("content-header")
        # $stderr.puts "parse_ht_string: #{str}" if debug
        return $1 if /\Atext:(.*)\Z/ =~ str
        ss = StringScanner.new(str)
        ht = root = Ht.new(tag: :div)
        class_a = []
        if ss.scan(/(\w+)/)
          ht[:tag] = ss[1].to_sym
          # $stderr.puts "tag=#{ht[:tag]}" if debug
        end
        until ss.eos?
          if ss.scan(/\.([a-zA-Z][a-zA-Z0-9_\-]*)/)
            class_a.push(ss[1])
            ht[:class] ||= class_a
          elsif ss.scan(/\#([a-zA-Z][a-zA-Z0-9_\-]*)/)
            ht[:id] = ss[1].to_sym
          elsif ss.scan(/\s*>\s*([a-zA-Z\.][a-zA-Z0-9_\-]*)/)
            parent = ht
            class_a = []
            if ss[1][0] == "."
              cls = ss[1][1..-1]
              class_a.push(cls)
              tag = :div
            else
              tag = ss[1].to_sym
            end
            # $stderr.puts "> chain: #{ss[1]}" if debug
            parent[:child] = ht = { tag: tag, class: class_a }
          elsif ss.scan(/:/)
            if ss.scan(/([a-zA-Z][a-zA-Z0-9_\-\.]+)=\[([^\]]+)\]/)
              ht[ss[1].to_sym] = ss[2]
            elsif ss.scan(/([a-zA-Z][a-zA-Z0-9_\-\.]+)=\{([^\}]+)\}/)
              ht[ss[1].to_sym] = ss[2]
            elsif ss.scan(/([a-zA-Z][a-zA-Z0-9_\-^.]+)=\(([^\)]+)\)/)
              ht[ss[1].to_sym] = ss[2]
            elsif ss.scan(/([a-zA-Z][a-zA-Z0-9_\-^.]+)=([^:]+)/)
              ht[ss[1].to_sym] = ss[2]
            end
          else
            ht[:child] = str[ss.pos..-1]
            # $stderr.puts "get child: pos=#{ss.pos}, #{ht}" if debug
            return root
          end
        end
        # $stderr.puts "root=#{root}" if debug
        return root
      end
    end
  end
end
