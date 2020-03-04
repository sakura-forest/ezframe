require_relative "../test_helper.rb"

class ColumnTypeTest < GenericTest
  def test_column_type
    assert_equal("text", TextType.type_name)
    obj = TextType.new({ key: "v1", type: "text", label: "mylabel" })
    form = obj.form
    assert_equal("input", form[:tag])
    assert_equal("mylabel", form[:label])
  end
end
