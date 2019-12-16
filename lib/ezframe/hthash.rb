module Ezframe
  module Ht
    class << self
      def wrap_tag(opts = {})
        h = opts.dup
        raise "Ht.wrap_tag: value must be a hash: #{h}" unless h.is_a?(Hash)
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
      alias_method :ul, :wrap_tag
      alias_method :ol, :wrap_tag
      alias_method :li, :wrap_tag
      alias_method :table, :wrap_tag
      alias_method :thead, :wrap_tag
      alias_method :tbody, :wrap_tag
      alias_method :tr, :wrap_tag
      alias_method :th, :wrap_tag
      alias_method :td, :wrap_tag
      alias_method :img, :wrap_tag
      alias_method :a, :wrap_tag
      alias_method :form, :wrap_tag
      alias_method :button, :wrap_tag
      alias_method :input, :wrap_tag
      alias_method :select, :wrap_tag
      alias_method :textarea, :wrap_tag
      alias_method :label, :wrap_tag
      alias_method :fieldset, :wrap_tag

      alias_method :icon, :wrap_tag
      alias_method :checkbox, :wrap_tag
      alias_method :radio, :wrap_tag

      def multi_wrap(class_a, child)
        class_a.reverse.each do |klass|
          child = Ht.div(class: klass, child: child)
        end
        return child
      end
    end

    class List
      attr_accessor :array

      def initialize(tag: "ul", array: [])
        @tag = tag
        @array = array.dup
      end

      def to_hash
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
      attr_accessor :class_a, :header

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

      def to_hash
        table_class, tr_class, td_class = @class_a
        max_col = 0
        @matrix.each { |row| max_col = row.length if max_col < row.length }
        tr_a = @matrix.map do |row|
          add_attr = nil
          add_attr = { colspan: max_col - row.length + 1 } if row.length < max_col
          td_a = row.map { |v| Ht.td(class: td_class, child: v) }
          td_a[0].update(add_attr) if add_attr
          Ht.tr(class: tr_class, child: td_a)
        end
        tr_a.unshift( Ht.thead(child: Ht.tr(child: @header.map {|v| Ht.th(child: v) }) )) if @header
        Ht.table(class: table_class, child: tr_a)
      end
    end
  end
end
