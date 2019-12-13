# frozen_string_literal: true

require 'minitest/autorun'
require 'ezframe/hthash.rb'

class HthashTest < Minitest::Test
  include Ezframe

  def test_wrap_tag
    assert_equal({ tag: "div", child: "test"},  Ht.div(child: "test"))
    assert_equal({ tag: "input", name: "test"},  Ht.input(name: "test"))
    assert_equal({ tag: "span", child: "test"},  Ht.span(child: "test"))
  end

  def test_class
    Hthash.new(tag: )
  end
end