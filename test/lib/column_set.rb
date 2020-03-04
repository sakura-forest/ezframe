# frozen_string_literal: true

require_relative '../test_helper.rb'

class ColumnTypeTest < GenericTest
  def test_contents
    columns = [
      { key: 'v1', type: 'text', label: 'label1' },
      { key: 'v2', type: 'int', label: 'label2' },
      { key: 'menu', type: 'select', label: 'menulabel', item: { opt1: 'value1', opt2: 'value2', opt3: 'value3' } }
    ]
    colset = ColumnSet.new(name: 'testcols', columns: columns)
    form = colset.form.compact
    assert_equal('input', form[0][:tag])
    assert_equal('input', form[1][:tag])
    assert_equal('select', form[2][:tag])

    colkeys = columns.map {|c| c[:key] }
    labels = colkeys.map {|k| colset[k].label }
    assert_equal(%w[label1 label2 menulabel], labels)

    # colset[:id].attribute.delete(:hidden)
    labels = colkeys.map {|k| colset[k].label }
    assert_equal(%w[label1 label2 menulabel], labels)
  end
end
