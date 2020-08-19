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
          if ht_h[:tag]
            h = { child: ht_h }
          else
            h = ht_h.dup
          end
        else
          EzLog.info("[WARN] wrap_tag: unknown type: #{ht_h.inspect}")
          return nil
        end
        h[:tag] ||= __callee__.to_s.to_sym
        # h[:wrap] = true
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
        # h[:wrap] = true
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

      alias_method :html, :wrap_tag
      alias_method :head, :wrap_tag
      alias_method :body, :wrap_tag
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
        return nil if ht_h.nil? || class_a.nil? || class_a.empty?
        cls = [ ht_h[:class] ].flatten
        class_a = [ class_a ].flatten
        ht_h[:class] = (Array(cls) + Array(class_a)).compact.uniq
        return ht_h
      end

      # ハッシュを再帰的に探査して、指定されたタグの要素の配列を返す
      def search(ht_h, query)
        if query.is_a?(String)
          query = Ht.from_array(query)
        end
        if ht_h.is_a?(Hash)
          if _compare(query, ht_h)
            # @found.push(ht_h)
            return ht_h
          end
          if ht_h[:child]
            res = search(ht_h[:child], query)
            return res if res
          end
        elsif ht_h.is_a?(Array)
          ht_h.map do |h| 
            res = search(h, query) 
            return res if res
          end
        end
      end

      def _compare(query, hash)
        flag = nil
        cls_a = [ query[:class] ].flatten.compact
        target_class = [ hash[:class] ].flatten.compact
        cls_a.each do |c|
          return nil unless target_class.include?(c)          
        end
        query.keys.each do |k|
          next if k == :class
          return nil unless hash[k] && query[k] == hash[k]
        end
        return true
      end

      def from_array(arg)
        if arg.is_a?(String)
          return parse_ht_string(arg)
        elsif arg.is_a?(Hash)
          return arg
        elsif arg.respond_to?(:to_ht)
          return arg.to_ht
        else
          return _array_to_ht(arg)
        end
      end

      def _array_to_ht(array)
        return nil unless array
        res_a = []
        pointer = 0
        while pointer < array.length
          val = array[pointer]
          if val.respond_to?(:to_ht)
            $stderr.puts "_arrray_to_ht: to_ht: #{val}"
            res = val.to_ht
            $stderr.puts("to_ht: #{res}")
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
        $stderr.puts "parse_ht_string: #{str}" if debug
        return $1 if /\Atext:(.*)\Z/ =~ str
        ss = StringScanner.new(str)
        ht = root = { tag: :div }
        class_a = []
        if ss.scan(/(\w+)/)
          ht[:tag] = ss[1].to_sym
          $stderr.puts "tag=#{ht[:tag]}" if debug
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
            $stderr.puts "> chain: #{ss[1]}" if debug
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
            $stderr.puts "get child: pos=#{ss.pos}, #{ht}" if debug
            return root
          end
        end
        $stderr.puts "root=#{root}" if debug
        return root
      end

      # 複数階層のノードの一番内側のノード(childを持たない)にchildを設定する
      def connect_child(ht, child)
        bottom = get_bottom(ht)
        bottom[:child] = child if bottom.is_a?(Hash)
        return ht
      end

      def get_bottom(ht)
        return nil unless ht
        child = ht
        while(child[:child]) do
          child = child[:child]
        end
        return child
      end
    end

    class List
      attr_accessor :prepend, :append, :before, :after, :option

      def initialize(opts = {})
        @option = opts
        @item_a = []
        init_var
      end

      def init_var
      end

      def add_item(item, opts = {})
        @item_a.push(wrap_item(item, opts))
      end

      def add_prepend(item)
        @prepend ||= []
        @prepend.push(item)
      end

      def add_append(item)
        @append ||= []
        @append.push(item)
      end

      def add_before(item)
        @before ||= []
        @before.push(item)
      end

      def add_after(item)
        @after ||= []
        @after.push(item)
      end

      def wrap_item(item, opts = {})
        item_tag = opts[:item_tag] || @option[:item_tag]
        unless item_tag
          return item
        end
        ht = Ht.from_array(item_tag)

        if item.respond_to?(:to_ht)
          item = item.to_ht 
        elsif !item.is_a?(Hash)
          item = Ht.from_array(item)
        end
        Ht.add_class(ht, opts[:extra_item_class])
        Ht.connect_child(ht, item)
        return ht
      end

      def add_before_after(ht)
        res = [ @before, ht, @after ].compact
        res = res[0] if res.length == 1
        return res
      end

      def add_first_last(ch = nil)
        child_a = (ch || @item_a).clone
        child_a = @prepend + child_a if @prepend.is_a?(Array) && @prepend.length > 0
        child_a = child_a + @append if @append.is_a?(Array) && @append.length > 0
        return child_a
      end

      def to_ht
        # return nil if @item_a.empty?
        wrap_tag = @option[:wrap_tag] || "div"
        ht = Ht.from_array(wrap_tag)
        Ht.add_class(ht, @option[:extra_wrap_class])
        child_a = add_first_last
        Ht.connect_child(ht, child_a)
        EzLog.debug("List.to_ht: #{ht}: @item_a=#{@item_a}")
        return add_before_after(ht)
      end

      def length
        return @item_a.length
      end
    end

    # テーブルを生成するためのクラス
    # @header ... テーブルの先頭に付ける項目名の配列
    class Table < List
      attr_accessor :header

      def init_var
        @option[:row_tag] ||= "tr"
        @option[:column_tag] ||= "td"
        @option[:head_column_tag] ||= "th"
        @option[:head_row_tag] ||= "tr"
        @option[:wrap_tag] ||= "table"
      end

      def add_item(item, opts = {})
        @item_a.push([item, opts])
      end

      def to_ht
        max_col = 0
        # self.each { |row| max_col = row.length if max_col < row.length }
        children = @item_a.map do |row| 
          col_a, row_opt = row
          wrap_item(col_a, row_opt)
        end
        child_a = add_first_last(children)
        
        head_ht = nil
        if @header
          head_a = wrap_item(@header, column_tag: @option[:head_column_tag], row_tag: @option[:head_row_tag])
          EzLog.debug "head_a=#{head_a}"
          head_ht = Ht.thead(child: head_a)
        end
        table = Ht.from_array(@option[:wrap_tag])
        children = [ head_ht, Ht.tbody(children) ].compact
        children = children[0] if children.length == 1
        Ht.connect_child(table, children)
        return add_before_after(table)
      end

      def wrap_item(item_a, opts = {})
        res_a = item_a.map do |it|
          it = it.to_ht if it.respond_to?(:to_ht)
          tag = opts[:column_tag] || @option[:column_tag]
          td = Ht.from_array(tag)
          col_attr = opts[:col_attr]
          td.update(col_attr) if col_attr
          Ht.connect_child(td, it)
          td
        end
        row_tag = opts[:row_tag] || @option[:row_tag]
        row_ht = Ht.from_array(row_tag)
        row_attr = opts[:row_attr]
        row_ht.update(row_attr) if row_attr
        Ht.connect_child(row_ht, res_a)
        return row_ht
      end
    end
  end
end
