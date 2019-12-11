# frozen_string_literal: true

module Ezframe
  class ColumnSets
    attr_accessor :tables, :model
    
    def initialize
      @tables = {}
    end

    def load_files(dir)
      Dir["#{dir}/*.yml"].each do |filename|
        load_one_file(filename)
      end
    end

    def load_one_file(filename)
      table_name = $1 if filename =~ /(\w+).ya?ml$/
      begin
        yaml = YAML.load_file(filename)
      rescue
        mylog("YAML load error: #{filename}")
        return 
      end
      if yaml.length == 0
        mylog("[ERROR] columns file is empty: #{filename}")
        return
      end
      column_info = yaml.recursively_symbolize_keys
      # puts "load_one_file: filename=#{filename} column_info=#{column_info.inspect}"
      add(table_name, column_info)
    end

    def add(table_name, columns)
      @tables[table_name.to_sym] = tb = ColumnSet.new(parent: self, name: table_name, columns: columns)
      tb.set(columns)
    end

    def [](table_name)
      @tables[table_name]
    end

    def each
      @tables.each {|k, v| yield(k, v) }
    end
  end

  class ColumnSet
    attr_accessor :name, :parent

    def initialize(parent:, name: nil, columns: nil)
      @parent = parent
      @name = name 
      @columns ||= {}
      set(columns) if columns
    end

    def clear
      @columns.each do |key, col|
        col.value = nil
      end
    end

    def set(attr_a)
      @columns[:id] = IdType.new(key: "id", label: "ID", hidden: true, no_edit: true)
      attr_a.each do |attributes|
        attr = attributes.clone
        col_key = attr[:key]
        raise "no column key: #{attr.inspect}" unless col_key
        klass = TypeBase.get_class(attr[:type])
        unless klass
          raise "no such column type: #{attr[:type]}"
        else
          @columns[col_key.to_sym] = klass.new(attr)
        end
      end
      @columns[:created_at] = DateType.new(type: "date", key: "created_at", label: "生成日時", hidden: true, no_edit: true)
      @columns[:updated_at] = DateType.new(type: "date", key: "updated_at", label: "更新日時", hidden: true, no_edit: true)
      # mylog "set: #{@columns.inspect}"
      @columns.values.each {|col| col.parent = self }
      @columns
    end

    def dataset
      # puts "dataset: #{@model.inspect}"
      @parent.model.db.dataset(@name)
    end

    def set_from_db(id)
      data = dataset.where(id: id).first
      return nil unless data
      self.values = data
      return data
    end

    def save
      col_h = get_hash(:value)
      col_h.delete(:id)
      col_h.delete(:created_at)
      col_h[:updated_at] = Time.now
      p "save: #{col_h.inspect}"
      id = @columns[:id]
      if id.value.to_i > 0
        dataset.where(id: id.value).update(col_h)
      else
        dataset.insert(col_h)
      end
    end

    def update(id, key, value)
      dataset.where(id: id).update(key => value)
      column = @columns[key.to_sym]
      column.value = value
      return column
    end

    def values=(value_h)
      clear
      # puts "value_h=#{value_h.inspect}"
      value_h.each do |k, v|
        # puts "values=: k=#{k}, v=#{v}"
        col = @columns[k.to_sym]
        unless col
          mylog("no such column: #{k}")
          next
        end
        col.value = v
      end
    end

    def values
      @columns.map {|key, col| col.value}
    end  

    def each
      @columns.values.each {|column| yield(column) }
    end

    def map
      @columns.values.map {|column| yield(column) }
    end

    def get_matrix(method_a)
      @columns.map do |_key, col|
        method_a.map { |method| col.send(method) }
      end
    end

    def get_hash(method)
      res_h = {}  
      @columns.map do |key, col|
        res_h[key] = col.send(method)
      end
      res_h
    end

    def [](col_key)
      @columns[col_key.to_sym]
    end
    
    def form
      res = @columns.values.map do |coltype|
        coltype.form
      end
      res.compact
    end

    def hidden_form
      @columns.map do |colkey, coltype|
        { tag: 'input', id: colkey, name: colkey, type: 'hidden', value: coltype.value }
      end
    end
  end
end
