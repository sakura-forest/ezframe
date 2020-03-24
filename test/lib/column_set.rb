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

    res = colset.validate({ v2: "abcd０１２" })
    assert_equal([ "abcd012", :invalid_value], res[:v2])
    res = colset.validate({ v2: "１２" })
    assert_equal([ "12", nil ], res[:v2])
  end

  def test_full_join_structure
    ColumnSets.init
    # 複数のcolumn setの組み合わせで取得したいカラムの構造生成
    columns1 = [
      { key: 'v1', type: 'text', label: 'label1' },
      { key: 'v2', type: 'int', label: 'label2' },
    ]
    columns2 = [
      { key: 'v1', type: 'text', label: 'label1' },
      { key: 'v2', type: 'int', label: 'label2' },
      { key: 'columns1', type: 'foreign', label: 'foregin3' },
    ]
    colset1 = ColumnSets.add(:columns1, columns1)
    colset2 = ColumnSets.add(:columns2, columns2)

    structure = ColumnSets.full_join_structure(:columns2)
    assert_equal([ :columns2, :columns1 ], structure[ :tables ])
    assert_equal([ 
      "columns2.id","columns2.v1", "columns2.v2", "columns2.created_at", "columns2.updated_at",
      "columns2.columns1","columns1.id","columns1.v1","columns1.v2", "columns1.created_at", "columns1.updated_at"].sort,
      structure[:column_list].sort)
  end

  def test_column_set_collection
    ColumnSets.init
    columns1 = [
      { key: 'v1', type: 'int', label: 'label1' },
      { key: 'v2', type: 'int', label: 'label2' },
    ]
    columns2 = [
      { key: 'v1', type: 'int', label: 'label1' },
      { key: 'v2', type: 'int', label: 'label2' },
      { key: 'columns1', type: 'foreign', label: 'foregin3' },
    ]
    colset1 = ColumnSets.add(:columns1, columns1)
    colset2 = ColumnSets.add(:columns2, columns2)

    collection = ColumnSetCollection.new
    collection.values = { "columns1.v1": 1, "columns1.v2": 2, "columns2.v1": 3, "columns2.v2": 4 }
    column = collection.get("columns1", "v1")
    assert column
    assert_equal(1, column.value)
    assert_equal(2, collection.get("columns1", "v2").value)
    assert_equal(3, collection.get("columns2", "v1").value)
    assert_equal(4, collection.get("columns2", "v2").value)
  end
end
