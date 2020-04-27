# frozen_string_literal: true
module Ezframe
  class DB
    class << self
      attr_accessor :sequel, :pool

      def init(dbfile = nil, opts = {})
        @dbfile = dbfile || ENV["EZFRAME_DB"] || Config[:database]
        if Config[:use_connection_pool] || opts[:use_connection_pool]
          @pool = Sequel::ConnectionPool(max_connections: 10) do
            Sequel.connect(@dbfile, loggers: [EzLog])
          end
        else
          connect(@dbfile)
        end
      end

      def connect(dbfile = nil)
        dbfile ||= @dbfile
        @sequel = Sequel.connect(dbfile, EzLogs: [EzLog])
        return @sequel
      end

      def disconnect
        @sequel.disconnect
      end

      def get_conn
        if @pool
          @pool.hold {|conn| return conn }
        else
          @sequel
        end
      end

      def exec(sql, first: nil)
        conn = get_conn
        if first
          return conn[sql].first
        else
          return conn[sql].all
        end
      end

      def run(sql)
        conn = get_conn
        conn.run(sql)
      end

      def dataset(table_name)
        @sequel[table_name.to_sym]
      end

      class JointHash < Hash
        def initialize(default_table, values = {})
          @default_table = default_table
          self.update(values)
        end

        def []=(key, value)
          super(key.to_s, value)
        end

        def [](key)
          key = key.to_s
          return fetch(key) if has_key?(key)
          alt_key = "#{@default_table}.#{key}"
          return fetch(alt_key) if has_key?(alt_key)
          return nil
        end
      end

      # テーブルを連結して、全てのデータを返す。
      def get_join_table(structure, opts = {})
        col_h = {}
        reverse_col_h = {}
        query_a = []
        table_a = []
        prefix="_x_"
        structure[:column_list].each_with_index do |k, i|
          key = "#{prefix}#{i+1}"
          col_h[k.to_sym] = key.to_sym
          reverse_col_h[key.to_sym] = k
          query_a.push "#{k} AS #{key}"
        end
        tables = structure[:tables].clone
        join_cond = structure[:join_condition]
        tb = tables.shift
        table_part = [ tb ]
        tables.each do |table|
          cond = join_cond[table.to_sym]
          if cond
            table_part.push " LEFT JOIN #{table} ON #{cond}"
          else
            table_part.push " LEFT JOIN #{table} ON #{tb}.#{table} = #{table}.id"
          end
        end
        sql = "SELECT #{query_a.join(', ')} FROM #{table_part.join(' ')}"
        sql += " WHERE #{opts[:where]}" if opts[:where]
        sql += " ORDER BY #{opts[:order]}" if opts[:order]
        sql += " LIMIT #{opts[:limit]}" if opts[:limit]
        data_a = self.exec(sql)
        res_a = []
        data_a.each do |data|
          new_data = JointHash.new(tb)
          data.each do |k, v|
            orig_key = reverse_col_h[k.to_sym]
            next unless orig_key
            new_data[orig_key] = v
          end
          res_a.push(new_data)
        end
        return res_a
      end

      # テーブル生成
      def create_table(table_name, dbtype_h)
        %w[id created_at updated_at deleted_at].each do |key|
          dbtype_h.delete(key.to_sym)
        end
        # puts "create_table: #{table_name}"
        if @dbfile.index("postgres")
          @sequel.create_table(table_name) do
            primary_key :id, identity: true
            dbtype_h.each do |key, dbtype|
              column(key, dbtype)
            end
            column(:created_at, :timestamp, default: Sequel::CURRENT_TIMESTAMP)
            column(:updated_at, :timestamp)
            column(:deleted_at, :timestamp)
          end
        else
          @sequel.create_table(table_name) do
            primary_key :id, auto_increment: true
            dbtype_h.each do |key, dbtype|
              column(key, dbtype)
            end
            column(:created_at, :timestamp, default: Sequel::CURRENT_TIMESTAMP)
            column(:updated_at, :timestamp)
            column(:deleted_at, :timestamp)
          end
        end
      end

      def insert(table_name, val_h)
        dataset(table_name).insert(val_h)
      end

      def update(dataset, id, val_h)
        val_h.update({ updated_at: Time.now })
        dataset.where(id: id).update(val_h)
      end

      def delete(dataset, id)
        dataset.where(id: id).update({ deleted_at: Time.now })
      end
    end

    class Cache
      class << self

        def [](table)
          @store ||= {}
          dataset = DB.dataset(table.to_sym)
          # EzLog.debug("DB::Cache: #{table}")
          unless @store[table.to_sym]
            data_a = dataset.where(deleted_at: nil).all
            h = {}
            data_a.each {|data| h[data[:id]] = data }
            @store[table.to_sym] = h
          end
          # EzLog.debug(@store[table.to_sym])
          return @store[table.to_sym]
        end
      end
    end
  end
end
