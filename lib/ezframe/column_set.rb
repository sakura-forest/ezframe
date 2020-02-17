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
      #begin
        yaml = YAML.load_file(filename)
      #rescue
      #  raise "YAML load error: #{filename}"
      #end
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
      return @tables[table_name]
    end

    def each
      @tables.each {|k, v| yield(k, v) }
    end
  end

  class ColumnSet
    attr_accessor :name, :parent, :edit_keys, :view_keys

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

    # 配列を初期化する
    def set(attr_a)
      @columns[:id] = IdType.new(key: "id", label: "ID", no_edit: true)
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
      @columns[:created_at] = DatetimeType.new(type: "datetime", key: "created_at", label: "生成日時", no_edit: true)
      @columns[:updated_at] = DatetimeType.new(type: "datetime", key: "updated_at", label: "更新日時", no_edit: true)
      # mylog "set: #{@columns.inspect}"
      @columns.values.each {|col| col.parent = self }
      return @columns
    end

    def dataset
      # puts "dataset: #{@model.inspect}"
      return @parent.model.db.dataset(@name)
    end

    def set_from_db(id)
      data = dataset.where(id: id).first
      return nil unless data
      self.values = data
      return data
    end

    # 新規に値を登録する
    def create
      col_h = get_hash(:value)
      col_h.delete(:id)
      col_h.delete(:created_at)
      col_h[:updated_at] = Time.now
      mylog "create: #{col_h.inspect}"
      id = @columns[:id]
      if id.value.to_i > 0
        dataset.where(id: id.value).update(col_h)
      else
        return dataset.insert(col_h)
      end
    end

    # データベース上の値の更新
    def update(id, value_h)
      self.set_from_db(id)
      updated_values = {}
      @columns.each do |colkey, column|
        next if column.no_edit?
        if column.multi_inputs?
          new_value = column.form_to_value(value_h)
        else
          new_value = value_h[colkey]
        end
        prev_value = column.value
        column.value = new_value
        if prev_value != column.value
          updated_values[colkey] = column.value
        end
      end
      mylog "column_set.updated_values = #{updated_values.inspect}"
      if updated_values.length > 0
        updated_values[:updated_at] = Time.now
        dataset.where(id: id).update(updated_values) 
      end
    end

    def values=(value_h)
      clear
      set_values(value_h)
    end

    def set_values(value_h)
      return unless value_h
      value_h.each do |k, v|
        next if k.nil? || k.to_s.empty?
        col = @columns[k.to_sym]
        next unless col
        col.value = v
      end
    end

    def validate
      clear_error
      errors = []
      @columns.values.each do |col| 
        err = col.validate
        errors.push([ col.key, err ]) if err
      end
      return errors
    end

    def clear_error
      @columns.values.each {|col| col.error = nil }
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
      return @columns.map do |_key, col|
        method_a.map { |method| col.send(method) }
      end
    end

    def get_hash(method)
      res_h = {}  
      @columns.map do |key, col|
        res_h[key.to_sym] = col.send(method)
      end
      return res_h
    end

    def [](col_key)
      return @columns[col_key.to_sym]
    end
    
    def form
      if @edit_keys
        return @edit_keys.map do |key| 
          col = @columns[key.to_sym]
          unless col
            mylog "[ERROR] @edit_keys has unknown column:name=#{@name}:key=#{key}"
            next
          end
          col.form
        end
      else
        return  @columns.values.map {|coltype| coltype.form }
      end        
    end

    def view
      if @view_keys
        return @view_keys.map do |key| 
          col = @columns[key.to_sym]
          unless col
            mylog "[ERROR] @view_keys has unknown column:name=#{@name}:key=#{key}"
            next
          end
          col.view
        end
      else
        return  @columns.values.map {|coltype| coltype.view }
      end
    end

    def hidden_form
      return @columns.map do |colkey, coltype|
        { tag: 'input', id: colkey, name: colkey, type: 'hidden', value: coltype.value }
      end
    end
  end
end
