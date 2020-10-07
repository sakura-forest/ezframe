class DBInfo
  def initialize
    @db_columns = {}
    @db_typ = get_database_type(Config[:database])
    case @db_typ
    when "postgresql"
      get_info_from_postgres
    when "sqlite"
      get_info_from_sqlite
    else
      raise "unknown database system"
    end
  end

  def get_db_info(table_name)
    return @db_columns[table_name.to_sym]
  end

  def get_info_from_postgres
    sql = "SELECT * FROM information_schema.columns"
    begin
      data_a = DB.sequel[sql].all
    rescue => e
      EzLog.error("get_info_from_postgres: #{e}")
      return nil
    end
    data_a.each do |row|
      table_name, col_name = row[:table_name], row[:column_name]
      next if col_name.nil? || table_name.nil?
      next unless ColumnSets.refer(table_name)
      @db_columns[table_name.to_sym] ||= {}
      @db_columns[table_name.to_sym][col_name.to_sym] = normalize_dbtype(row[:data_type])
    end
  end

  def get_info_from_sqlite
    sql = "SELECT * from sqlite_master;"
    data_a = DB.sequel[sql].all
    return nil unless data_a
    data_a.each do |data|
      sql = data[:sql]
      parse_create_sql(sql)
    end
  end

  def parse_create_sql(sql)
    # EzLog.debug("parse_create_sql: #{sql}")
    if sql =~ /CREATE TABLE \`(\w+)\` \(/i
      table_name = $1
    else
      return
    end
    @db_columns[table_name.to_sym] ||= {}
    column_a = sql.split(", ")
    column_a.each do |line|
      if line =~ /\`(\w+)\`\s(\w+)/
        colkey, dbtype = $1, $2
        @db_columns[table_name.to_sym][colkey.to_sym] = dbtype
      end
    end
  end

  def get_database_type(config)
    return config.split("://")[0]
  end

  def exec_sql(sql)
    begin
      DB.sequel.run(sql)
    rescue => e
      EzLog.error("dbmigrate: exec_sql: #{e}")
    end
  end

  def normalize_dbtype(dbtype)
    return nil unless dbtype
    return "int" if dbtype == "integer"
    return "timestamp" if dbtype.index("timestamp")
    return dbtype
  end

  def set_default(column)
    default_value = column.attribute[:default]
    if default_value
      unless %w[int].include?(column.db_type)
        default_value = "'#{default_value}'"
      end
      exec_sql("ALTER TABLE #{column.parent.name} ALTER #{column.key} SET DEFAULT #{default_value}")
    end
  end

  def check_diff(column_set)
    table_name = column_set.name
    dbcols = get_db_info(table_name)
    unless dbcols
      TableManager.create_one_table(table_name, ColumnSets.get(table_name.to_sym))
      return
    end
    column_set.each do |column|
      next if %w[id updated_at created_at deleted_at].include?(column.key.to_s)
      dbtype = dbcols[column.key]
      new_type = column.db_type
      if !new_type || new_type.empty?
        EzLog.debug("check_diff: no db_type: table=#{table_name}:key=#{column.key}")
        next
      end
      unless dbtype
        exec_sql("ALTER TABLE #{table_name} ADD #{column.key} #{new_type};")
        set_default(column)
        next
      end
      if dbtype != new_type
        exec_sql("ALTER TABLE #{table_name} ALTER COLUMN #{column.key} DROP DEFAULT;")
        unless change_type(table, column.key, new_type)
          # 失敗したときは名前を変更してカラム追加
          rename_column(table_name, column.key, "#{column.key}_bak")
          add_column(table, column.key, new_type)
        end
        set_default(column)
      end
    end
  end

  # カラム追加
  def add_column(table_name, key, typ)
    begin
      exec_sql("ALTER TABLE #{table_name} ADD #{key} #{typ};")
    rescue => e
      EzLog.error("change_type: error: #{e.class}:#{e}:#{e.backtrace}")
      return nil
    end
    return true
  end

  # カラムの型変更
  def change_type(table_name, key, typ)
    begin
      exec_sql("ALTER TABLE #{table_name} ALTER #{key} TYPE #{typ};")
    rescue => e
      EzLog.error("change_type: error: #{e.class}:#{e}:#{e.backtrace}")
      return nil
    end
    return true
  end

  # カラムの名前変更
  def rename_column(table_name, old_key, new_key)
    begin
      exec_sql("ALTER TABLE #{table_name} RENAME #{old_key} TO #{new_key};")
    rescue => e
      EzLog.error("rename_column: error: #{e.class}:#{e}:#{e.backtrace}")
      return nil
    end
    return true
  end
end

class TableManager
  class << self
    def create_tables
      ColumnSets.keys.each do |colset_key|
        column_set = ColumnSets[colset_key]
        begin
          create_one_table(colset_key, column_set)
        rescue => e
          EzLog.error("create_tables: #{e.inspect}\n#{$@.inspect}")
        end
      end
    end

    def create_one_table(table_name, column_set)
      # テーブル生成を含むカラムの扱い
      column_set.each do |column|
        table = column.attribute[:column]
        treat_sub_table(column_set, column.key, table) if table
      end
      col_h = column_set.get_hash(:db_type)
      create_table(table_name, col_h)
    end

    # テーブル生成
    def create_table(table_name, dbtype_h)
      %w[id created_at updated_at deleted_at].each do |key|
        dbtype_h.delete(key.to_sym)
      end
      # puts "create_table: #{table_name}"
      DB.sequel.create_table?(table_name) do
        if Config[:database].index("postgres")
          primary_key :id, identity: true
        else
          primary_key :id, auto_increment: true
        end
        dbtype_h.each do |key, dbtype|
          next unless dbtype
          column(key, dbtype)
        end
        column(:created_at, :timestamp, default: Sequel::CURRENT_TIMESTAMP)
        column(:updated_at, :timestamp)
        column(:deleted_at, :timestamp)
      end
    end

    def treat_sub_table(parent_column_set, key, table)
      table.unshift({ key: parent_column_set.name, type: "foreign" })
      table_name = "#{parent_column_set.name}_#{key}"
      # EzLog.debug("treat_sub_table: #{table_name}, #{table}")
      colset = ColumnSets.add(table_name, table)
      col_h = colset.get_hash(:db_type)
      create_table(table_name, col_h)
    end
  end
end
