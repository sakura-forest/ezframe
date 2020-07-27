# frozen_string_literal: true
require_relative "../test_helper.rb"

class HtTest < GenericTest
  def test_convert_tag
    assert_equal({ tag: :div, wrap: true, child: "test"},  Ht.div(child: "test"))
    assert_equal({ tag: :input, name: "test"},  Ht.input(name: "test"))
    assert_equal({ tag: :span, wrap: true, child: "test"},  Ht.span(child: "test"))
  end

  def test_div
    h = Ht.div(child: [Ht.div(child: "A"), Ht.div(child: "B")])
    assert_equal({ tag: :div, wrap: true, child: [ {tag: :div, wrap: true, child: "A"}, {tag: :div, wrap: true, child: "B"}]}, h)
  end

  def test_multidiv
    res = Ht.multi_div([%w[a b], %w[c d]], "test")
    assert_equal(%w[a b], res[:class])
    assert_equal(%w[c d], res[:child][:class])
    assert_equal("test", res[:child][:child])
  end

  def test_from_array
    ht_a = Ht.from_array([ "body.cl1", [ "ul#myid", [ "li", [ "a:href=http://www.asahi.com" ]]], ".wrapper", [ "span.cl2:child1", Ht.div(child: "div") ]])
    node1 = ht_a[0]
    assert_equal(:body, node1[:tag])
    assert_equal(%w[cl1], node1[:class])
    child = node1[:child][0]
    assert_equal(:ul, child[:tag])
    assert_equal(:myid, child[:id])
    child = child[:child][0]
    assert_equal(:li, child[:tag])
    child = child[:child][0]
    assert_equal(:a, child[:tag])
    assert_equal("http://www.asahi.com", child[:href])

    node2 = ht_a[1]
    assert_equal(:div, node2[:tag])
    assert_equal(%w[wrapper], node2[:class])
    child = node2[:child][0]
    assert_equal(:span, child[:tag])
    assert_equal(%w[cl2], child[:class])
    assert_equal("child1", child[:child])
    child = node2[:child][1]
    assert_equal(:div, child[:tag])
    assert_equal("div", child[:child])
  end
end