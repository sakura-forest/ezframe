# frozen_string_literal: true

require "singleton"

module Ezframe
  class Model
    class << self

      def init_column_sets
        @base_column_sets = ColumnSets.new
        @base_column_sets.load_files('./columns')
      end  

      def init_db
        @base_db = Database.new
      end

      def init
        unless @base_column_sets
          init_column_sets
          init_db
        end
      end

      def get_clone
        new(@base_column_sets.deep_dup, @base_db)
      end
    end

    attr_accessor :column_sets, :db

    def initialize(column_sets, db)
      @column_sets, @db = column_sets, db
      @column_sets.model = self
      # @column_sets.each {|name, colset| colset.model = self }
    end

    def create_tables
      @column_sets.tables.each do |table_name, column_set|
        begin
          create_one_table(table_name, column_set)
        rescue => e
          mylog("*** #{e.inspect}\n#{$@.inspect}")
        end
      end
    end

    def create_one_table(table_name, column_set)
      col_h = column_set.get_hash(:db_type)
      mylog "create_one_table: col_h=#{col_h.inspect}"
      @db.create_table(table_name, col_h)
    end  
  end
end