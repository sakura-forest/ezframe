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

  def test_force_arg
    columns = [
      { key: 'v1', type: 'text', label: 'label1' },
      { key: 'v2', type: 'int', label: 'label2' },
      { key: 'menu', type: 'select', label: 'menulabel', item: { opt1: 'value1', opt2: 'value2', opt3: 'value3' } }
    ]
    colset = ColumnSet.new(name: 'testcols', columns: columns)
    tm = Time.mktime(2020,4,4)
    colset[:created_at].value = tm
    assert(!colset[:created_at].view)
    assert_equal("2020/04/04 00:00:00", colset[:created_at].view(force: true))
  end

  def test_birthday_type
    columns = [
      { key: 'v1', type: 'text', label: 'label' },
      { key: 'v2', type: 'birthday', label: 'birthday' },
    ]
    colset = ColumnSet.new(name: 'testcols', columns: columns)

    colset.set_values({ v1: "testvalue", v2_year: 1989, v2_mon: 9, v2_mday: 10 })
    assert_equal("1989-09-10", colset[:v2].value)
    assert_equal("1989<small>年</small> 9<small>月</small>10<small>日</small>", colset[:v2].view)
    colset.set_values({ v1: "testvalue", v2: "1990-02-12"})
    assert_equal("1990-02-12", colset[:v2].value)
    assert_equal("1990<small>年</small> 2<small>月</small>12<small>日</small>", colset[:v2].view)
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

    columns3 = [
      { key: 'v1', type: 'text', label: 'label1' },
      { key: 'foreign_value', type: 'foreign', table: "columns1", column: "v2", label: 'foregin_special_name' },
    ]
    colset3 = ColumnSets.add(:columns3, columns3)

    structure = ColumnSets.full_join_structure(:columns3)
    assert_equal([ :columns3, :columns1 ], structure[ :tables ])
    join_condition = structure[:join_condition]
    assert_equal([ :columns1 ], join_condition.keys)
    assert_equal("columns3.foreign_value = columns1.v2", join_condition[:columns1])
    assert_equal([ 
      "columns3.id","columns3.v1", "columns3.created_at", "columns3.updated_at",
      "columns3.foreign_value","columns1.id","columns1.v1","columns1.v2", "columns1.created_at", "columns1.updated_at"].sort,
      structure[:column_list].sort)

    # １つのテーブルから、同じテーブルへのforeignが複数ある場合
    # とりあえず今は実装しない。
=begin
    columns4 = [
      { key: 'v1', type: 'text', label: 'label1' },
      { key: 'foreign1', type: 'foreign', table: "columns1",label: 'foregin_name1' },
      { key: 'foreign2', type: 'foreign', table: "columns1",label: 'foregin_name2' },
    ]
    colset4 = ColumnSets.add(:columns4, columns4)


    structure = ColumnSets.full_join_structure(:columns4)
    assert_equal([ :columns4, :columns1 ], structure[ :tables ])
    assert_equal([ ["foreign1", "column1", "columns1.id=columns4.foreign1"  ],
                    [ "foreign2", "column1", "columns1.id=columns4.foreign2"  ]
                  ], structure[ :join_condition ])
    assert_equal([ 
      "columns4.id","columns4.v1", "columns4.created_at", "columns4.updated_at",
      "foreign1.id","foreign1.v1","foreign1.v2","foreign2.v1","foreign2.v2",
      "columns1.id","columns1.v1","columns1.v2", "columns1.created_at", "columns1.updated_at"].sort,
      structure[:column_list].sort)
    end
=end
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
