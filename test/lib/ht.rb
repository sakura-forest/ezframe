# frozen_string_literal: true

require 'minitest/autorun'
require 'ezframe/ht.rb'

class HthashTest < Minitest::Test
  include Ezframe

  def test_convert_tag
    assert_equal({ tag: "div", child: "test"},  Ht.div(child: "test"))
    assert_equal({ tag: "input", name: "test"},  Ht.input(name: "test"))
    assert_equal({ tag: "span", child: "test"},  Ht.span(child: "test"))
  end

  def test_multidiv
    res = Ht.multi_div([%w[a b], %w[c d]], "test")
    assert_equal(%w[a b], res[:class])
    assert_equal(%w[c d], res[:child][:class])
    assert_equal("test", res[:child][:child])

    res = Ht.multi_div([%w[a b], "test")
    res = Ht.multi_div([%w[a b], "test")

  end
end