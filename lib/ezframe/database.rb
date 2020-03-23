# frozen_string_literal: true
require "logger"

module Ezframe
  class DB
    class << self
      attr_accessor :sequel, :pool

      def init(dbfile = nil, opts = {})
        @dbfile = dbfile || ENV["EZFRAME_DB"] || Config[:database]
        if Config[:use_connection_pool] || opts[:use_connection_pool]
          @pool = Sequel::ConnectionPool(max_connections: 10) do
            Sequel.connect(@dbfile, loggers: [Logger])
          end
        else
          connect(@dbfile)
        end
      end

      def connect(dbfile = nil)
        dbfile ||= @dbfile
        @sequel = Sequel.connect(dbfile, loggers: [Logger])
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

      def get_join_table(structure, where: nil)
        col_h = {}
        reverse_col_h = {}
        query_a = []
        table_a = []
        structure[:column_list].each_with_index do |k, i|
          key = "_x_joint_value#{i+1}"
          col_h[k.to_sym] = key.to_sym
          reverse_col_h[key.to_sym] = k
          query_a.push "#{k} AS #{key}"
        end
        tables = structure[:tables].clone
        tb = tables.shift
        table_part = [ tb]
        tables.each do |table|
          table_part.push " LEFT JOIN #{table} ON #{tb}.#{table} = #{table}.id"
        end
        sql = "SELECT #{query_a.join(', ')} FROM #{table_part.join(' ')}"
        sql += " WHERE #{where}" if where
        puts sql
        data_a = self.exec(sql)
        res_a = []
        p data_a
        data_a.each do |data|
          puts "data=#{data.inspect}"
          new_data = {}
          data.each do |k, v|
            orig_key = reverse_col_h[k.to_sym]
            next unless orig_key
            new_data[orig_key] = v
          end
          res_a.push(new_data)
        end
        return res_a
      end

      def create_table(table_name, dbtype_h)
        %w[id created_at updated_at].each do |key|
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
            column(:updated_at, :timestamp, default: Sequel::CURRENT_TIMESTAMP)
          end
        else
          @sequel.create_table(table_name) do
            primary_key :id, auto_increment: true
            dbtype_h.each do |key, dbtype|
              column(key, dbtype)
            end
            column(:created_at, :timestamp, default: Sequel::CURRENT_TIMESTAMP)
            column(:updated_at, :timestamp, default: Sequel::CURRENT_TIMESTAMP)
          end
        end
      end

      def insert(table_name, val_h)
        dataset(table_name).insert(val_h)
      end

      def update(dataset, val_h)
        val_h.update({ updated_at: Time.now() })
        dataset.update(val_h)
      end
    end
  end
end
