# frozen_string_literal: true
require "logger"

module Ezframe
  class Database
    attr_accessor :sequel

    def initialize(dbfile = "db/devel.sqlite")
      @dbfile = dbfile
      connect
    end  

    def connect
      @sequel = Sequel.connect("sqlite://#{@dbfile}", loggers: [Logger.new($stdout)])
    end  

    def exec(sql)
      @sequel.run(sql)  
    end  

    def dataset(table_name)
      @sequel[table_name.to_sym]  
    end
  
    def create_table(table_name, dbtype_h)
      %w[id created_at updated_at].each do |key|
        dbtype_h.delete(key.to_sym)
      end
      @sequel.create_table(table_name) do 
        primary_key :id, auto_increment: true
        dbtype_h.each do |key, dbtype|
          column(key, dbtype)
        end
        column(:created_at, :timestamp, default: Sequel::CURRENT_TIMESTAMP)
        column(:updated_at, :timestamp, default: Sequel::CURRENT_TIMESTAMP)
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
