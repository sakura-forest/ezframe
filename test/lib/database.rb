# frozen_string_literal: true

require "minitest/autorun"
require "lib/ezframe.rb"

class ColumnTypeTest < Minitest::Test
  def test_basic_table_management
    db_file = "db/test.sqlite"
    db = EzModel::Database.new(db_file)
    db.connect
    db.drop_table?
    db.create_table(table_name, { v1: "int", v2: "string" })
    100.times do |i|
      db.insert(table_name, { v1: i.to_s, v2: i })
    end  

    dataset = db.dataset(table_name)

    data_a = dataset.where{ v1 >= 90 }.all
    assert_equal(10, data_a.length)

    data_a = dataset.all
    assert_equal(100, data_a.length)
  end
end