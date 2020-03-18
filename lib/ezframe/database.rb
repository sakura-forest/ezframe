# frozen_string_literal: true
require "logger"

module Ezframe
  module Model
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

        def exec(sql)
          if @pool
            @pool.hold { |conn| conn.execute(sql) }
          else
            @sequel.run(sql)
          end
        end

        def dataset(table_name)
          @sequel[table_name.to_sym]
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
end
