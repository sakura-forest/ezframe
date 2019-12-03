# frozen_string_literal: true

require 'minitest/autorun'
require 'lib/ezframe'

class ColumnTypeTest < Minitest::Test
  def test_contents
    columns = [
      { key: 'v1', type: 'string', label: 'label1' },
      { key: 'v2', type: 'int', label: 'label2' },
      { key: 'menu', type: 'select', label: 'menulabel', items: { opt1: 'value1', opt2: 'value2', opt3: 'value3' } }
    ]
    colset = EzModel::ColumnSet.new(name: 'testcols', columns: columns)
    form = colset.form
    # p form
    assert_equal('input', form[0][:tag])
    assert_equal('input', form[1][:tag])
    assert_equal('select', form[2][:tag])

    labels = colset.map {|col| p col.label }.compact
    assert_equal(%w[label1 label2 menulabel], labels)

    colset[:id].attribute.delete(:hidden)
    labels = colset.map {|col| p col.label }.compact
    assert_equal(%w[ID label1 label2 menulabel], labels)
  end
end
