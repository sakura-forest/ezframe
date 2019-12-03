require "minitest/autorun"
require "lib/column_type"

class ColumnTypeTest < Minitest::Test
  include EzModel
  
  def test_column_type
    assert_equal("string", StringType.type_name)
    assert_equal(StringType, TypeDict.get(:string))
    assert_equal(IntegerType, TypeDict.get(:int))
    obj = StringType.new({ type: "string", label: "mylabel" })
    form = obj.form
    assert_equal("input", form[:tag])
    assert_equal("mylabel", form[:label])
  end

  def test_foreign
    sets=ColumnSets.new  
    ColumnSet.new("customer", [{ key: name, type: string, label: "氏名" }])
    ColumnSet.new("order", { key: 'customer', type: "foreign", view: 'name' })

    assert_equal  
  end
end
