require_relative "../test_helper.rb"

class ColumnTypeTest < GenericTest
  def test_column_type
    assert_equal("text", TextType.type_name)
    obj = TextType.new({ key: "v1", type: "text", label: "mylabel" })
    form = obj.form
    assert_equal("input", form[:tag])
    assert_equal("mylabel", form[:label])
  end

  def test_textarea_type
    obj = TextareaType.new({ key: "tx1", type: "textarea", label: "label1"})
    text = "123\n456\n789"
    obj.value = text
    assert_equal(text, obj.value)
    assert_equal(text, obj.view)
  end

  def test_zipcode_type
    obj = ZipcodeType.new({ key: "zipcode", type: "zipcode", label: "label1"})
    v = 1234567
    assert(!obj.validate(v))
    v = "abcdef"
    assert_equal(:invalid_value, obj.validate(v))
  end

  def test_tel_type
    obj = TelType.new({ key: "k1", type: "tel", label: "label1"})
    assert !obj.validate("0921234567")
    assert !obj.validate("09012345678")
    assert_equal :invalid_value,  obj.validate("092")
    assert_equal :invalid_value, obj.validate("0901231341234123412")
    assert "090", obj.normalize("＝９＝")
  end
end
