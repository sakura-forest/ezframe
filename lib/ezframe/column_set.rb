# frozen_string_literal: true

module Ezframe
  class ColumnSets
    class << self
      def init(dir = nil)
        dir ||= "./column"
        unless @colset_h
          @colset_h = {}
          load_files(dir)
        end
      end

      def load_files(dir)
        Dir["#{dir}/*.yml"].each do |filename|
          load_one_file(filename)
        end
      end

      def load_one_file(filename)
        colset_name = $1 if filename =~ /(\w+).ya?ml$/
        yaml = YAML.load_file(filename)
        if yaml.length == 0
          EzLog.error("[ERROR] columns file is empty: #{filename}")
          return
        end
        column_info = yaml.recursively_symbolize_keys
        # puts "load_one_file: filename=#{filename} column_info=#{column_info.inspect}"
        add(colset_name, column_info)
      end

      def add(colset_name, columns)
        @colset_h[colset_name.to_sym] = cs = ColumnSet.new(parent: self, name: colset_name, columns: columns)
        cs.set(columns)
        return cs
      end

      def clone
        @colset_h.deep_dup
      end

      def has_key?(key)
        return nil unless key
        return @colset_h[key.to_sym]
      end

      def get(colset_name)
        return nil unless colset_name
        return @colset_h[colset_name.to_sym].deep_dup
      end

      def refer(colset_name)
        return nil unless colset_name
        return @colset_h[colset_name.to_sym]
      end

      def [](colset_name)
        return get(colset_name)
      end

      def each
        @colset_h.each { |k, v| yield(k, v) }
      end

      def inspect
        @colset_h.each do |name, colset|
          "[#{name}]:#{colset.inspect}"
        end
      end

      def create_tables
        self.each do |table_name, column_set|
          begin
            create_one_table(table_name, column_set)
          rescue => e
            EzLog.error("create_tables: #{e.inspect}\n#{$@.inspect}")
          end
        end
      end

      def create_one_table(table_name, column_set)
        col_h = column_set.get_hash(:db_type)
        EzLog.info "create_one_table: col_h=#{col_h.inspect}"
        DB.create_table(table_name, col_h)
      end

      # foreignから生成したテーブル連結情報を返す
      def full_join_structure(colset_id)
        struct = { tables: [colset_id] }
        colset = @colset_h[colset_id.to_sym]
        colset_keys = colset.keys
        struct[:column_list] = colset_keys.map { |k| "#{colset_id}.#{k}" }
        join_cond_h = {}
        colset_keys.each do |key|
          column = colset[key]
          if column.type.to_s == "foreign"
            # 連結するテーブル名をtable: で指定する。
            foreign_table = column.attribute[:table]
            # 指定されてなければ、キーの名称をテーブル名とする
            # そのテーブルが定義されてなければ、エラーとしてログに残す。
            unless foreign_table
              if @colset_h[key]
                foreign_table = key
              else
                EzLog.error "There is no related table: #{key}"
                next
              end
            end
            raise "no table: key=#{key}" unless foreign_table
            foreign_column = column.attribute[:column]&.to_sym || :id
            foreign_table = foreign_table.to_sym
            next if struct[:tables].include?(foreign_table)
            # join_cond_h["#{colset_id}.#{key}"] = "#{colset_id}.#{key} = #{foreign_table}.#{foreign_column}"
            join_cond_h[foreign_table] = "#{colset_id}.#{key} = #{foreign_table}.#{foreign_column}"
            struct[:tables].push(foreign_table)
            struct[:column_list] += ColumnSets.refer(foreign_table).keys.map {|k| "#{foreign_table}.#{k}" }
          end
        end
        struct[:join_condition] = join_cond_h
        return struct
      end

      def join_complex_column

      end
    end
  end

  # ColumnSetを複数組み合わせて扱う
  class ColumnSetCollection
    attr_accessor :colset_list

    def initialize(default_table=nil)
      @colset_h = {}
      @default_table = default_table
    end

    def values=(data)
      @colset_h.each {|key, colset| colset.clear }
      set_values(data)
    end

    def set_values(data)
      data.each do |key, value|
        if key.to_s.index(".")
          table_key, col_key = key.to_s.split(".")
          colset = @colset_h[table_key.to_sym]
          unless colset
            @colset_h[table_key.to_sym] = colset = ColumnSets[table_key]
          end
        elsif @default_table
          col_key = key
          colset = @colset_h[@default_table.to_sym]
          unless colset
            @colset_h[table_key.to_sym] = colset = ColumnSets[@default_table]
          end
        end
        colset[col_key].value = value
      end
    end

    def get(colset_key, col_key=nil)
      if col_key.nil?
        if colset_key.to_s.index(".")
          colset_key, col_key = colset_key.to_s.split(".")
        elsif @default_table
          colset_key, col_key =  @default_table, colset_key
        else
          EzLog.error "ColumnSetCollection.get: illegal arguments: #{colset_key}, #{col_key}"
          return nil
        end
      end
      colset = @colset_h[colset_key.to_sym]
      return nil unless colset
      # EzLog.debug("Collection.get: colset_key=#{colset_key}, col_key=#{col_key}, value=#{colset[col_key].value}")
      return colset[col_key]
    end

    def [](k)
      return get(k)
    end
  end

  class ColumnSet
    attr_accessor :name, :parent # , :edit_keys, :view_keys

    def initialize(parent: nil, name: nil, columns: nil)
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

    def keys
      @columns.keys
    end

    def edit_keys
      @columns.keys.select {|k| !@columns[k].no_edit? }
    end

    def view_keys
      @columns.keys.select {|k| !@columns[k].no_view? }
    end

    # 配列を初期化する
    def set(attr_a)
      @columns[:id] = IdType.new(key: "id", label: "ID", hidden: true)
      attr_a.each do |attribute|
        attr = attribute.clone
        col_key = attr[:key]
        raise "no column key: #{attr.inspect}" unless col_key
        klass = TypeBase.get_class(attr[:type])
        unless klass
          raise "no such column type: #{attr[:type]}"
        else
          @columns[col_key.to_sym] = klass.new(attr)
        end
      end
      @columns[:created_at] = DatetimeType.new(type: "datetime", key: "created_at", label: "生成日時", hidden: true)
      @columns[:updated_at] = DatetimeType.new(type: "datetime", key: "updated_at", label: "更新日時", hidden: true)
      @columns[:deleted_at] = DatetimeType.new(type: "datetime", key: "deleted_at", label: "削除日時", hidden: true)
      @columns.values.each { |col| col.parent = self }
      return @columns
    end

    def dataset
      return DB.dataset(@name)
    end

    def set_from_db(id)
      data = dataset.where(id: id).first
      self.clear
      return nil unless data
      self.set_values(data, from_db: true)
      return data
    end

    def set_from_form(form, key_suffix: nil)
      self.clear
      self.set_values(form)
    end

    # データベースに新規に値を登録する
    def create(value_h, from_db: nil, key_suffix: nil)
      self.clear
      if from_db
        self.set_values(value_h, from_db: true, key_suffix: key_suffix)
      else
        self.set_values(value_h, key_suffix: key_suffix)
      end
      db_value_h = self.get_hash(:db_value)
      EzLog.debug("column_set.create: #{db_value_h}")
      db_value_h.delete(:id)
      db_value_h[:updated_at] = Time.now
      db_value_h[:created_at] = Time.now
      EzLog.debug("create: sql=#{dataset.insert_sql(db_value_h)}")
      return dataset.insert(db_value_h)
    end

    # データベース上の値の更新
    def update(id, value_h)
      self.set_from_db(id)
      updated_values = {}
      @columns.each do |colkey, column|
        next if column.no_edit?
        if column.respond_to?(:form_to_value)
          new_value = column.form_to_value(value_h)
        else
          new_value = value_h[colkey]
        end
        prev_value = column.db_value
        column.value = new_value
        # EzLog.debug("key=#{colkey}, pre_value=#{prev_value}, new_value=#{column.db_value}")
        if column.respond_to?("value_equal?")
          unless column.value_equal?(prev_value, column.db_value)
            updated_values[colkey] = column.db_value
          end
        elsif prev_value != column.db_value
          updated_values[colkey] = column.db_value
        end
      end
      if updated_values.length > 0
        updated_values[:updated_at] = Time.now
        sql = dataset.where(id: id).update_sql(updated_values)
        EzLog.debug("update: sql=#{sql}")
        dataset.where(id: id).update(updated_values)
      end
    end

    # 各カラムに値を格納する
    def set_values(value_h, from_db: nil, key_suffix: nil)
      self.clear
      return self unless value_h
      # EzLog.debug("set_values: name=#{self.name}, keys=#{@columns.keys}, value_h=#{value_h}")
      @columns.keys.each do |key|
        next if key.to_s.empty?
        target_key = key
        target_key = "#{key}#{key_suffix}" if key_suffix
        column = @columns[key.to_sym]
        if !from_db && column.respond_to?(:form_to_value) # && !value_h.has_key?(key)
          val = column.form_to_value(value_h, target_key: target_key)
        else
          val = value_h[target_key.to_sym] || value_h[key]
        end
        # EzLog.debug("key=#{column.key}, target_key=#{target_key}, value = #{val}")
        column.value = val
      end
      return self
    end

    def values=(value_h)
      set_values(value_h)
    end

    # 各カラムのバリデーション
    # 戻り値は[ 正規化した値, エラーシンボル(Messageのキーと紐づく) ]を値として、
    # カラムキーをキーとするハッシュ
    def validate(value_h)
      return {} unless value_h
      clear_error
      result_h = {}
      @columns.values.each do |col|
        res = []
        if col.respond_to?(:form_to_value) && !value_h.has_key?(col.key)
          orig_val = col.form_to_value(value_h)
        else
          orig_val = value_h[col.key]
        end
        new_val = col.normalize(orig_val)
        res[0] = new_val if orig_val != new_val
        res[1] = col.validate(new_val)
        result_h[col.key] = res if res[0] || res[1]
      end
      return result_h
    end

    def clear_error
      @columns.values.each { |col| col.error = nil }
    end

    def values
      @columns.map { |key, col| col.value }
    end

    def each
      @columns.values.each { |column| yield(column) }
    end

    def map
      @columns.values.map { |column| yield(column) }
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
                   EzLog.info "[ERROR] @edit_keys has unknown column:name=#{@name}:key=#{key}"
                   next
                 end
                 col.form
               end
      else
        return @columns.values.map { |coltype| coltype.form }
      end
    end

    def view
      if @view_keys
        return @view_keys.map do |key|
                 col = @columns[key.to_sym]
                 unless col
                   EzLog.info "[ERROR] @view_keys has unknown column:name=#{@name}:key=#{key}"
                   next
                 end
                 col.view
               end
      else
        return @columns.values.map { |coltype| coltype.view }
      end
    end

    def get_full_join(opts = {})
      struct = ColumnSets.full_join_structure(self.name)
      return DB.get_join_table(struct, opts)
    end

    def hidden_form
      return @columns.map do |colkey, coltype|
               { tag: "input", id: colkey, name: colkey, type: "hidden", value: coltype.value }
             end
    end

    def inpsect
      @columns.map do |colkey, coltype|
        "#{colkey}=#{coltype.value}"
      end.join(" ")
    end
  end
end
