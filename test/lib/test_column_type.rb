# coding: utf-8
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
    assert "090", obj.normalize("０９０")
  end

  def test_birthday
    obj = BirthdayType.new({ key: "k1", type: "birthday", label: "label1"})
    form = { k1_year: 1988, k1_mon: 11, k1_mday: 22 }
    new_val = obj.form_to_value(form)
    assert_equal("1988-11-22", new_val)
    obj.value = new_val
    assert_equal("1988<small>年</small>11<small>月</small>22<small>日</small>", obj.view)
  end

  def test_view_format
    obj = DateType.new({ key: "k1", type: "date", label: "label1", view_format: ["%d/%02d/%02d", :year, :mon, :mday] })    
    obj.value = "2020-04-05"
    assert_equal("2020/04/05", obj.view)
    obj = DateType.new({ key: "k1", type: "date", label: "label1", view_format: ["%d<tag>%02d</tag>%02d", :year, :mon, :mday] })    
    obj.value = "2020-04-05"
    assert_equal("2020<tag>04</tag>05", obj.view)
  end

  def test_password_type
    obj = PasswordType.new({ key: "k1", type: "password", label: "label1" })
    obj.value = raw_pass = "abcdef"
    assert(obj.db_value.index("$"))
    assert(obj.value_equal?(obj.db_value, raw_pass))
  end
end
