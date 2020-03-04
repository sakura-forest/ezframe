require_relative "../test_helper.rb"

class ColumnTypeTest < GenericTest
  def test_column_type
    assert_equal("text", TextType.type_name)
    obj = TextType.new({ key: "v1", type: "text", label: "mylabel" })
    form = obj.form
    assert_equal("input", form[:tag])
    assert_equal("mylabel", form[:label])
  end

  def test_textarea
    obj = TextareaType.new({ key: "tx1", type: "textarea", label: "label1"})
    text = "123\n456\n789"
    obj.value = text
    assert_equal(text, obj.value)
    assert_equal(text, obj.view)
  end
end
