# frozen_string_literal: true
require_relative "../test_helper.rb"

class HthashTest < GenericTest
  def test_convert_tag
    assert_equal({ tag: "div", wrap: true, child: "test"},  Ht.div(child: "test"))
    assert_equal({ tag: "input", name: "test"},  Ht.input(name: "test"))
    assert_equal({ tag: "span", wrap: true, child: "test"},  Ht.span(child: "test"))
  end

  def test_div
    h = Ht.div(child: [Ht.div(child: "A"), Ht.div(child: "B")])
    assert_equal({ tag: "div", wrap: true, child: [ {tag: "div", wrap: true, child: "A"}, {tag: "div", wrap: true, child: "B"}]}, h)
  end

  def test_multidiv
    res = Ht.multi_div([%w[a b], %w[c d]], "test")
    assert_equal(%w[a b], res[:class])
    assert_equal(%w[c d], res[:child][:class])
    assert_equal("test", res[:child][:child])
  end

end