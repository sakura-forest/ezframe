#coding: utf-8
require_relative "../test_helper.rb"

class Test < GenericTest
  def test_table
    a = [ [ 1,2,3 ], [ 4,5,6 ], [ 7,8,9 ] ]

    table = PageStruct::Table.new
    table.set_value(a)
    table.set_head(%w[h1 h2 h3])
    ht = table.to_ht
    p ht
    assert_equal(:table, ht[:tag])
    thead, tbody = ht[:child]
    assert_equal(:thead, thead[:tag])
    assert_equal(3, thead[:child].length)
    assert_equal(:tbody, tbody[:tag])
    tr_a = tbody[:child]
    assert_equal(3, tr_a.length)
    tr = tr_a[0]
    assert_equal(:tr, tr[:tag])
    td_a = tr[:child]
    assert(td_a.is_a?(Array))
    assert(3, td_a.length)
    p td_a
    td = td_a[0]
    assert_equal(:td, td[:tag])
    assert_equal(1, td[:child])
    td = td_a[1]
    assert_equal(:td, td[:tag])
    assert_equal(2, td[:child])

    tr = tr_a[1]
    td_a = tr[:child]
    assert(td_a.is_a?(Array))
    assert(3, td_a.length)
    td = td_a[0]
    assert_equal(:td, td[:tag])
    assert_equal(4, td[:child])
    td = td_a[1]
    assert_equal(:td, td[:tag])
    assert_equal(5, td[:child])
  end
end
