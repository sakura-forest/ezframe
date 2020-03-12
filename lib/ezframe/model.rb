# frozen_string_literal: true

module Ezframe
  class Model
    class << self
      attr_accessor :current

      def init_column_sets(columns_dir = nil)
        columns_dir ||= "./columns"
        @base_column_sets = ColumnSets.new
        @base_column_sets.load_files(columns_dir)
      end  

      def init_db(database = nil)
        @base_db = Database.new(database)
      end

      def init(columns_dir: nil, database: nil)
        unless @base_column_sets
          init_column_sets(columns_dir)
          init_db(database)
        end
      end

      def get_clone
        @current = new(@base_column_sets.deep_dup, @base_db)
        return @current
      end
    end

    attr_accessor :column_sets, :db

    def initialize(column_sets, db)
      @column_sets, @db = column_sets, db
      @column_sets.model = self
    end

    def create_tables
      @column_sets.tables.each do |table_name, column_set|
        begin
          create_one_table(table_name, column_set)
        rescue => e
          Logger.info("*** #{e.inspect}\n#{$@.inspect}")
        end
      end
    end

    def create_one_table(table_name, column_set)
      col_h = column_set.get_hash(:db_type)
      Logger.info "create_one_table: col_h=#{col_h.inspect}"
      @db.create_table(table_name, col_h)
    end  
  end
end