module Ezframe
  class PageStruct
    class Node
      attr_accessor :value, :option      

      def initialize(val = nil, opt = nil)
        @value = val
        @option = opt
      end

      def to_ht
        h = Ht.div(child: val)
        h.update(@option) if @option
        return h
      end
    end

    class Divs
      def initialize(val = nil, opt = nil)
        @value = val ? Array.new(val) : []
        @option = opt
      end

      def add_value(value = nil, option = nil)
        if value.respond_to?(:to_ht)
          @value.push(value)
        else
          @value.push(Node.new(value, option))
        end
      end

      def to_ht
        line = self.map do |v|
          if v.respond_to?(:to_ht)
            v.to_ht
          else
            Ht.div(child: v)
          end
        end
        h = Ht.div(child: line)
        h.update(@option) if @option
        return h
      end
    end
  end

  class Table
    class Line < Array
      def initialize(val_a)
        self.new(val_a) if val_a
      end
    end

    attr_accessor :option

    def initialize(val_a = nil)
      set_value(value) if val_a
      @thead = nil
      @tbody = []
      @option = {}
    end

    def set_header(val_a)
      @thead  = Array.new(val_a)
    end

    def set_value(val_a)
      # 最初の値がHashだったら、@optionとして保存
      if val_a[0].is_a?(Hash)
        @option = value.shift
      end
      val_a.each do |row|
        @tbody.push(Line.new(row))
      end
    end

    def add_line(val_a)
      @tbody.push(Line.new(val_a))
    end

    def to_ht
      res_a = []
      if @thead
        th_a = @thead.map {|v| Ht.th(v) }
        tr = Ht.tr(th_a)
        tr.update(@option[:header_opt]) if @option[:header_opt]
        res_a.push(Ht.thead(tr))
      end
      if @tbody.length > 0
        tbody_a = @tbody.map do |line|
          line.map do |col| 
            if col.respond_to?("to_ht")
              col.to_ht
            else
              Ht.td(col)
            end
          end
        end
        res_a.push(Ht.tbody(tr_a))
      end
    end
  end
end