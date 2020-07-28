# HTMLを中間表現としてのハッシュであるhthashを生成するためのクラス
require "strscan"

module Ezframe
  module Ht
    class << self
      # メソッド名の名前のタグのhthashを生成
      def wrap_tag(ht_h = {})
        return nil unless ht_h
        if ht_h.is_a?(String) || ht_h.is_a?(Array)
          h = { child: ht_h }
        elsif ht_h.is_a?(Hash)
          h = ht_h.dup
        else
          EzLog.info("[WARN] wrap_tag: unknown type: #{ht_h.inspect}")
          return nil
        end
        h[:tag] ||= __callee__.to_s.to_sym
        h[:wrap] = true
        raise "no tag" if h[:tag] == "wrap_tag"
        return h
      end

      def single_tag(ht_h = {})
        ht_h[:tag] ||= __callee__.to_s.to_sym
        raise "no tag" if ht_h[:tag] == "wrap_tag"
        raise "has child: #{ht_h.inspect}" if ht_h[:child]
        return ht_h
      end

      def script(ht)
        if ht.is_a?(String)
          h = { src: ht }
        else
          h = ht.clone
        end
        h[:tag] = :script
        h[:wrap] = true
        return h
      end

      def css(ht)
        if ht.is_a?(String)
          h = { href: ht }
        else
          h = ht.clone
        end
        h[:tag] = :link
        h[:rel] = "stylesheet"
        return h
      end

      alias_method :title, :wrap_tag

      alias_method :h1, :wrap_tag
      alias_method :h2, :wrap_tag
      alias_method :h3, :wrap_tag
      alias_method :h4, :wrap_tag
      alias_method :h5, :wrap_tag
      alias_method :h6, :wrap_tag
      alias_method :p, :wrap_tag
      alias_method :br, :single_tag
      alias_method :hr, :single_tag
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
      alias_method :meta, :single_tag
      alias_method :img, :single_tag
      alias_method :a, :wrap_tag
      alias_method :form, :wrap_tag
      alias_method :input, :single_tag
      alias_method :select, :wrap_tag
      alias_method :option, :wrap_tag
      alias_method :textarea, :wrap_tag
      alias_method :label, :wrap_tag
      alias_method :fieldset, :wrap_tag
      alias_method :nav, :wrap_tag
      alias_method :aside, :wrap_tag
      alias_method :footer, :wrap_tag

      alias_method :small, :wrap_tag
      alias_method :pre, :wrap_tag
      alias_method :iframe, :wrap_tag

      alias_method :checkbox, :wrap_tag
      alias_method :radio, :wrap_tag

      # materialize用のiconメソッド
      # 引数が文字列だったら、それをname属性とする
      def icon(arg)
        if arg.is_a?(Hash)
          h = arg.clone
          h[:tag] = "icon"
          return wrap_tag(h)
        elsif arg.is_a?(String)
          return { tag: "icon", wrap: true, name: arg }
        end
      end

      # buttonタグにはデフォルトでtype=button属性を付ける
      def button(arg)
        arg[:tag] = "button"
        unless arg[:type]
          arg[:type] = "button"
        end
        wrap_tag(arg)
      end

      # 複数のDIVをまとめて生成
      def multi_div(class_a, child)
        class_a.reverse.each do |klass|
          child = Ht.div(class: klass, child: child)
        end
        return child
      end

      # ハッシュにclassを追加
      def add_class(ht_h, class_a)
        cls = ht_h[:class]
        cls = [] unless cls
        ht_h[:class] = Array.new(cls) + Array.new(class_a)
      end

      # ハッシュを再帰的に探査して、指定されたタグの要素の配列を返す
      def search(ht_h, opts)
        @found ||= []
        if ht_h.is_a?(Hash)
          if opts[:tag] && ht_h[:tag] && ht_h[:tag] == opts[:tag]
            @found.push(ht_h)
          end
          if ht_h[:child]
            search(ht_h[:child], opts)
          end
        elsif ht_h.is_a?(Array)
          ht_h.map { |h| search(h, opts) }
        end
        return @found
      end

      def from_array(array)
        return _array_to_ht(array)
      end

      def _array_to_ht(array)
        return nil unless array
        res_a = []
        pointer = 0
        while pointer < array.length
          val = array[pointer]
          if val.is_a?(Hash)
            res_a.push(val)
            pointer += 1
            next
          elsif val.is_a?(String)
            ht = parse_ht_string(val)
            next_val = array[pointer + 1]
            if next_val.is_a?(Array)
              ht[:child] = tmp = _array_to_ht(next_val)
              puts "tmp=#{tmp}"
              pointer += 1
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
        puts "parse_ht_string: #{str}"
        ss = StringScanner.new(str)
        ht = root = { tag: :div }
        class_a = []
        if ss.scan(/(\w+)/)
          ht[:tag] = ss[1].to_sym
          puts "tag=#{ht[:tag]}"
        end
        until ss.eos?
          if ss.scan(/\.([a-zA-Z][a-zA-Z0-9_\-]*)/)
            class_a.push(ss[1])
            ht[:class] ||= class_a
          elsif ss.scan(/\#([a-zA-Z][a-zA-Z0-9_\-]*)/)
            ht[:id] = ss[1].to_sym
          elsif ss.scan(/\s*>\s*([a-zA-Z][a-zA-Z0-9_\-]*)/)
            parent = ht
            class_a = []
            parent[:child] = ht = { tag: ss[1].to_sym }
          elsif ss.scan(/:([a-zA-Z][a-zA-Z0-9_\-]+)=\[([^\]]+)\]/)
            ht[ss[1].to_sym] = ss[2]
          elsif ss.scan(/:([a-zA-Z][a-zA-Z0-9_\-]+)=\{([^\}]+)\}/)
            ht[ss[1].to_sym] = ss[2]
          elsif ss.scan(/:([a-zA-Z][a-zA-Z0-9_\-]+)=\(([^\)]+)\)/)
            ht[ss[1].to_sym] = ss[2]
          elsif ss.scan(/:([a-zA-Z][a-zA-Z0-9_\-]+)=([^:]+)/)
            ht[ss[1].to_sym] = ss[2]
          else
            ht[:child] = str[ss.pos+1..-1]
            puts "get child: pos=#{ss.pos}, #{ht}"
            return root
          end
        end
        p root
        return root
      end

      def parse_ht_string_old(str)
        ht = {}
        class_a = []
        if str.index(":")
          tag_section = str.split(":")[0]
        else
          tag_section = str
        end
        tag_section.scan(/\A([a-z]+)/) { ht[:tag] = $1.to_sym }
        tag_section.scan(/\.([a-zA-Z][a-zA-Z0-9_\-]+)/) { class_a.push($1) }
        tag_section.scan(/\#([a-zA-Z][a-zA-Z0-9_\-]+)/) { ht[:id] = $1.to_sym }
        prev_key = nil
        str.scan(/\:([^:]+)/) do 
          misc = $1
          if /\A\/\// =~ misc
            ht[prev_key] += ":#{misc}"
            next
          end
          if misc =~ /([a-zA-Z\-\_]+)=(.*)/
            key, value = $1.to_sym, $2
            ht[key] = value
            prev_key = key
          else
            ht[:child] = misc
          end
        end
        ht[:class] = class_a unless class_a.empty?
        ht[:tag] ||= :div
        return ht
      end
    end

    class Node
      attr_accessor :option

      def initialize(opts = nil)
        @option = opts || {}
      end

      def add_child(child)
        return nil unless child
        child_a = @option[:child]
        if child_a
          child_a = Array.new(ch) unless child_a.is_a?(Array)
        else
          child_a = []
        end
        child_a += Array.new(child)
        @option[:child] = child_a
        return self
      end

      def add_class(klass)
        return nil unless klass
        classs_a = @option[:class]
        if class_a
          class_a = Array.new(class_a) unless class_a.is_a?(Array)
        else
          classs_a = []
        end
        class_a += Array.new(klass)
        @option[:class] = class_a
        return self
      end

      def to_ht
        @option[:tag] ||= :div
        return Ht.wrap_tag(@option)
      end
    end

    # 配列を<UL><OL>要素に変換するためのクラス
    class List < Array
      attr_accessor :tag
      def to_ht(opts = {})
        return nil if self.empty?
        child = self.map { |elem| Ht.li(elem) }
        h = { tag: @tag, wrap: true, child: child }
        h.update(opts)
        return h
      end
    end

    # 配列を<UL>要素に変換するためのクラス
    class Ul < List
      def to_ht(opts = {})
        @tag = :ul
        return super(opts)
      end
    end

    # 配列を<OL>要素に変換するためのクラス
    class Ol < List
      def to_ht(opts = {})
        @tag = :ol
        return super(opts)
      end
    end

    # テーブルを生成するためのクラス
    # @matrix ... テーブルの内容となる二次元配列
    # @header ... テーブルの先頭に付ける項目名の配列
    # @class_a ... <table><tr><td>の各ノードにそれぞれ設定したいclass属性を配列として定義
    class Table
      attr_accessor :class_a, :header, :matrix

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

      def to_ht
        table_class, tr_class, td_class = @class_a
        max_col = 0
        @matrix.each { |row| max_col = row.length if max_col < row.length }
        tr_a = @matrix.map do |row|
          add_attr = nil
          add_attr = { colspan: max_col - row.length + 1 } if row.length < max_col
          td_a = row.map do |v| 
            td = Ht.td(child: v) 
            td.add_class(td_class) if td_class
            td
          end
          td_a[0].update(add_attr) if add_attr
          tr = Ht.tr(class: tr_class, child: td_a)
          tr.add_class(tr_class) if tr_class
          tr
        end
        tr_a.unshift( Ht.thead(child: Ht.tr(child: @header.map {|v| Ht.th(child: v) }) )) if @header
        tb = Ht.table(child: tr_a)
        tb.add_class(table_class) if table_class
        tb
      end
    end
  end
end
