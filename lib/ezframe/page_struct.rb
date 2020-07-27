require_relative "ht"

module Ezframe
  class PageStruct
    class Node
      attr_accessor :value, :option, :tag

      def initialize(val = nil, opt = nil)
        @value = val
        @option = opt
        @tag = :div
      end

      def to_ht
        h = Ht.wrap_tag(tag: @tag, child: @value)
        h.update(@option) if @option.is_a?(Hash)
        return h
      end

      def to_s
        @value
      end
    end

    class Table
      class Row < Array
        def initialize(val_a, opt = nil)
          @option = opt
          set_value(val_a) if val_a.is_a?(Array)
        end

        def set_value(row)
          row.each do |col|
            add_column(col)
          end
        end

        def add_column(col, opt = nil)
          unless col.respond_to?(:to_ht)
            col = Column.new(col, opt)
          end
          self.push(col)
          return col
        end

        def to_ht
          res_a = self.map do |col|
            if col.respond_to?(:to_ht)
              col.to_ht
            else
              col.to_s
            end
          end
          h = Ht.tr(res_a)
          h.update(@option) if @option
          return h
        end

        def to_s
          self.map {|v| v.to_s }.join(", ")
        end
      end

      class Column < PageStruct::Node
        def initialize(val = nil, opt)
          super(val, opt)
          @tag = :td
        end
      end

      attr_accessor :option

      def initialize(val_a = nil, opt = nil)
        @tbody = []
        @thead = nil
        @option = opt
        set_value(value) if val_a
      end

      def set_head(val_a)
        @thead = Array.new(val_a)
      end

      def set_value(val_a)
        # 最初の値がHashだったら、@optionとして保存
        # @option = val_a.shift if val_a[0].is_a?(Hash) 

        val_a.each do |row| 
          add_row(row)
        end
      end

      def add_row(row = nil)
        unless row.respond_to?(:to_ht)
          row = Row.new(row)
        end
        @tbody.push(row)
        return row
      end

      def to_ht
        res_a = []
        if @thead
          th_a = @thead.map { |v| Ht.th(v) }
          tr = Ht.tr(th_a)
          tr.update(@option[:header_opt]) if @option && @option[:header_opt]
          res_a.push(Ht.thead(tr))
        end
        if @tbody.length > 0
          tbody_a = @tbody.map { |row| row.to_ht }
          res_a.push(Ht.tbody(child: tbody_a))
        end
        res_a = res_a[0] if res_a.length == 1
        h = Ht.table(child: res_a)
        h.update(@option) if @option
        return h
      end

      def to_s
        self.map {|v| v.to_s }.join("\n")
      end
    end

    class Container < Array
      class Row < Array
        def initialize(val_a, opt)
          super(val_a) if val_a
          @option = opt
        end

        def set_value(val_a)
          self.replace(val_a) if val_a.is_a?(Array)
        end

        def add_column(col)
          if col.respond_to?(:to_ht)
            @values.push(col)
          else
            col = Column.new(col)
            @values.push(col)
          end
          return col
        end

        def to_ht
        end
      end

      class Column < PageStruct::Node
        def initialize(val, opt)
          super(val, opt)
          @tag = :div
        end
      end

      attr_accessor :option

      def initialize(matrix = nil, opt = nil)
        set_value(matrix) if val_a.is_a?(Array)
        @option = opt
      end

      def set_value(matrix)
        matrix.each do |a|
          add_row(a)
        end
      end

      def add_row(row, opt = nil)
        unless row.respond_to?(:to_ht)
          row = Row.new(row, opt)
        end
        self.push(row)
        return row
      end

      def to_ht
        rows = self.map do |row|
          row.to_ht
        end
        h = Ht.div(child: rows)
        h.update(@option) if @option
        return h
      end
    end
  end
end
