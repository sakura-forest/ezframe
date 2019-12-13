module Ezframe
  class Ht < Hash
    class << self
      def wrap_tag(opts={})
        h = opts.dup
        h[:tag] = __callee__.to_s
        h
      end

      alias_method :h1, :wrap_tag
      alias_method :h2, :wrap_tag
      alias_method :h3, :wrap_tag
      alias_method :h4, :wrap_tag
      alias_method :h5, :wrap_tag
      alias_method :h6, :wrap_tag
      alias_method :p, :wrap_tag
      alias_method :br, :wrap_tag
      alias_method :hr, :wrap_tag
      alias_method :div, :wrap_tag
      alias_method :span, :wrap_tag
      alias_method :i, :wrap_tag
      alias_method :strong, :wrap_tag
      alias_method :icon, :wrap_tag
      alias_method :ul, :wrap_tag
      alias_method :ol, :wrap_tag
      alias_method :li, :wrap_tag
      alias_method :table, :wrap_tag
      alias_method :tr, :wrap_tag
      alias_method :th, :wrap_tag
      alias_method :td, :wrap_tag
      alias_method :img, :wrap_tag
      alias_method :a, :wrap_tag
      alias_method :form, :wrap_tag
      alias_method :button, :wrap_tag
      alias_method :input, :wrap_tag
      alias_method :textarea, :wrap_tag
      alias_method :label, :wrap_tag
      alias_method :fieldset, :wrap_tag
    end

    def multi_wrap(class_a, child)
      class_a.reverse.each do |klass|
        child = { tag: "div", class: klass, child: child }
      end
      return child
    end

    def add_class(klass)
      c = self[:class]
      if c.is_a?(String)
        a = [ c ]
        self[:class] = c = a
      end
      if klass.is_a?(Array)
        klass.each {|k| add_class(k) }
      else
        return if c.include?(klass)
        c.push(klass)
      end
    end

    class List
      attr_accessor :array

      def initialize(tag: "ul", array: [])
        @tag = tag
        @array = array.dup
      end

      def to_hthash
        return nil if @list.nil? || @list.empty?
        child = @array.map do |elem|
          { tag: "li", child: elem }
        end
        { tag: @tag, child: child }
      end
    end

    class Ul < List
      def initialize(array: [])
        super(tag: "ul", array: array)
      end
    end

    class Ol < List
      def initialize(array: [])
        super(tag: "ol", array: array)
      end
    end


    class Table
      def initialize(matrix = nil)
        set(matrix) if matrix
        @matrix ||= []
      end

      def set(matrix)
        @matrix = matrix
      end

      def add_row(row)
        @matrix.push(row)
      end

      def to_hthash
        max_col = 0
        @matrix.each { |row| max_col = row.length if max_col < row.length }
        tr_a = @matrix.map do |row|
          add_attr = nil
          add_attr = { colspan: max_col - row.length + 1 } if row.length < max_col
          td_a = row.map { |v| { tag: 'td', child: v } }
          td_a[0].update(add_attr) if add_attr
          { tag: 'tr', child: td_a }
        end
        { tag: 'table', child: tr_a }
      end
    end
  end
end
