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

  def test_get_join_table
    init_test_db
    DB.create_table(:table1, { v1: "int", v2: "int", table2: "int" })
    DB.create_table(:table2, { v1: "int", v2: "int" })
    DB.insert(:table1, { v1: 1, v2: 2, table2: 1 })
    DB.insert(:table2, { v1: 5, v2: 6 })
    DB.insert(:table1, { v1: 3, v2: 4, table2: 2 })
    DB.insert(:table2, { v1: 7, v2: 8 })

    struct = { tables: [ :table1, :table2 ], column_list: %w[table1.v1 table1.v2 table2.v1 table2.v2 ]  }
    data_a = DB.get_join_table(struct, where: "table1.id=1")
    p data_a
    assert_equal(1, data_a.length)
    data = data_a[0]
    assert_equal(1, data["table1.v1"])
    assert_equal(2, data["table1.v2"])
    assert_equal(5, data["table2.v1"])
    assert_equal(6, data["table2.v2"])

    data_a = DB.get_join_table(struct, where: "table1.id=2")
    assert_equal(1, data_a.length)
    data = data_a[0]
    assert_equal(3, data["table1.v1"])
    assert_equal(4, data["table1.v2"])
    assert_equal(7, data["table2.v1"])
    assert_equal(8, data["table2.v2"])
  end
end