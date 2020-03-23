# frozen_string_literal: true

require_relative "../test_helper.rb"

class DatabaseTest < GenericTest
  def test_basic_table_management
    basic_test(use_connnection_pool: true)
  end

  def test_use_connection_pool
    basic_test(use_connnection_pool: true)
  end

  def basic_test(opts = {})
    db_file = "db/test.sqlite"
    db_url = "sqlite://#{db_file}"
    File.unlink(db_file) if File.exist?(db_file)
    DB.init(db_url, use_connnection_pool: opts[:use_connnection_pool])
    DB.connect
    table_name = "test_table"
    DB.create_table(table_name, { v1: "int", v2: "string" })
    100.times do |i|
      DB.insert(table_name, { v1: i.to_s, v2: i })
    end

    dataset = DB.dataset(table_name)

    data_a = dataset.where{ v1 >= 90 }.all
    assert_equal(10, data_a.length)

    data_a = dataset.all
    assert_equal(100, data_a.length)
    DB.disconnect
  end
end