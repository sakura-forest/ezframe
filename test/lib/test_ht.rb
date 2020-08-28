# frozen_string_literal: true
require_relative "../test_helper.rb"

class HtTest < GenericTest
  def test_convert_tag
    assert_equal({ tag: :div, child: "test"},  Ht.div(child: "test").to_h)
    assert_equal({ tag: :div, child: "test"},  Ht.div("test").to_h)
    assert_equal({ tag: :thead, child: { tag: :div, child: "test" }},  Ht.thead(Ht.div("test")).to_h)
    assert_equal({ tag: :input, name: "test"},  Ht.input(name: "test").to_h)
    assert_equal({ tag: :span, child: "test"},  Ht.span(child: "test").to_h)
  end

  def test_div
    ht = Ht.div(child: [Ht.div(child: "A"), Ht.div(child: "B")])
    assert_equal(:div, ht[:tag])
    child_a = ht[:child]
    assert_equal(2, child_a.length)
    a = child_a[0]
    assert_equal(:div, a[:tag])
    assert_equal("A", a[:child])
    b = child_a[1]
    assert_equal(:div, b[:tag])
    assert_equal("B", b[:child])
  end

  def test_multidiv
    res = Ht.multi_div([%w[a b], %w[c d]], "test")
    assert_equal(%w[a b], res[:class])
    assert_equal(%w[c d], res[:child][:class])
    assert_equal("test", res[:child][:child])
  end

  def test_compact
    ht = Ht.compact("div")
    puts "ht.class=#{ht.class}, value=#{ht}"
    assert_equal({ tag: :div }, ht.to_h)

    ht_a = Ht.compact("body.cl1", [ "ul#myid", [ "li", [ "a:href=[http://www.asahi.com]:asahi" ]]], ".wrapper", [ "span.cl2:child1", Ht.div(child: "child_text") ])
    puts "test_compact: ht_a=#{ht_a}"
    node1 = ht_a[0]
    assert_equal(:body, node1[:tag])
    assert_equal(%w[cl1], node1[:class])
    child = node1[:child][0]
    assert_equal(:ul, child[:tag])
    assert_equal(:myid, child[:id])
    child = child[:child][0]
    assert_equal(:li, child[:tag])
    # puts "child=#{child}"
    child = child[:child][0]
    assert_equal(:a, child[:tag])
    assert_equal("http://www.asahi.com", child[:href])
    assert_equal("asahi", child[:child])

    node2 = ht_a[1]
    assert_equal(:div, node2[:tag])
    assert_equal(%w[wrapper], node2[:class])
    child_a = node2[:child]
    assert(child_a.is_a?(Array))
    assert_equal(2, child_a.length)
    child = child_a[0]
    assert_equal(:span, child[:tag])
    assert_equal(%w[cl2], child[:class])
    assert_equal("child1", child[:child])
    child = child_a[1]
    assert_equal(:div, child[:tag])
    assert_equal("child_text", child[:child])

    # 連続するdiv
    ht_a = Ht.compact([ ".div1>span.span2>a:href=index.html", [ ".child1", ".child2" ] ])
    # p ht_a
    child1 = ht_a[0]
    assert_equal(:div, child1[:tag])
    assert_equal(["div1"], child1[:class])
    child2 = child1[:child]
    assert_equal(:span, child2[:tag])
    assert_equal(["span2"], child2[:class])
    child3 = child2[:child]
    assert_equal(:a, child3[:tag])
    assert_equal("index.html", child3[:href])
    # assert_equal("test", child3[:child])
    child4 = child3[:child]
    assert_equal(Array, child4.class)
    assert_equal(2, child4.length)
    assert_equal(%w[child1], child4[0][:class])
    assert_equal(%w[child2], child4[1][:class])

    # 様々な引数
    ht_a = Ht.compact([ ".div1:v1=[http://localhost:9292/index.html]:v2={:test:}" ])
    node = ht_a[0]
    assert_equal("http://localhost:9292/index.html", node[:v1])
    assert_equal(":test:", node[:v2])
  end

  def test_table
    table = Ht::Table.new
    table.add_item([ "v1", "v2", "v3" ])
    table.add_item([ "v4", "v5", "v6" ])
    table.add_item([ "v4", "v5", "v6" ])

    res = table.to_ht
    assert_equal(:table, res[:tag])
    child = res[:child]
    assert_equal(:tbody, child[:tag])
    child = child[:child]
    assert(child.is_a?(Array))
    # p child
    assert_equal(3, child.length)
    child = child[0]
    assert_equal(:tr, child[:tag])
    child = child[:child]
    assert_equal(Array, child.class)
    assert_equal(3, child.length)
    col = child[0]
    assert_equal(:td, col[:tag])

    table.option[:wrap_tag] = "table_dummy.table-class"
    table.option[:row_tag] = "tr_dummy.tr-class"
    table.option[:column_tag] = "td_dummy.td-class"
    res = table.to_ht
    assert_equal(:table_dummy, res[:tag])
    assert_equal(%w[table-class], res[:class])
    child = res[:child]
    assert_equal(:tbody, child[:tag])
    child = child[:child]
    assert_equal(Array, child.class)
    child = child[0]
    assert_equal(:tr_dummy, child[:tag])
    assert_equal(%w[tr-class], child[:class])
    child = child[:child]
    assert(child.is_a?(Array))
    assert_equal(3, child.length)
    col = child[0]
    assert_equal(:td_dummy, col[:tag])
    assert_equal(%w[td-class], col[:class])

    table.header = [ "k1", "k2", "k3" ]
    res = table.to_ht
    assert_equal(:table_dummy, res[:tag])
    child = res[:child]
    assert_equal(2, child.length)
    thead, tbody = child
    assert_equal(:thead, thead[:tag])
    assert_equal(:tbody, tbody[:tag])
  end
  
  def test_connect_child
    ht = Ht.compact(".div1 > .div2")
    ht2 = Ht.a(href: "#remote", child: "link")
    Ht.connect_child(ht, ht2)
    child = ht[:child][:child]
    child[:tag] = :a
    child[:child] = "link"
  end

  def test_search
    ht = Ht.compact([".link2", [ ".div2", [ "a.link1:href=[link1.html]", "a.link2:href=[link2.html]",] ]])
    res = Ht.search(ht, ".link2")
    assert_equal(:div, res[:tag])    
    res = Ht.search(ht, "a.link2")
    assert_equal(:a, res[:tag])    
    assert_equal("link2.html", res[:href])    

    res = Ht.search(ht, { class: "link1"})
    assert_equal("link1.html", res[:href])    
  end

  def test_list
    list = Ht::List.new    
    list.add_item("item1")
    list.add_item("item2")
    list.add_item("item3")
    ht = list.to_ht
    puts ht
    assert(:div, ht[:tag])
    child = ht[:child]
    assert_equal(3, child.length)
    item = child[0]
    assert(item.is_a?(String))

    list = Ht::List.new(wrap_tag: "ul.class1", item_tag: "li")
    list.add_item(".item1:item1")
    list.add_item(".item2:item2")
    list.add_item(".item3:item3")
    ht = list.to_ht
    puts ht
    assert(:ul, ht[:tag])
    child = ht[:child]
    assert_equal(3, child.length)
    item = child[0]
    assert_equal(:li, item[:tag])
  end
end