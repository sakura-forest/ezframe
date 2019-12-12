# frozen_string_literal: true

require 'minitest/autorun'
require 'ezframe/util.rb'

class MaterializeTest < Minitest::Test
  def test_add_class
    h = { a: 1, b: 2, class: "a" }
    h.add_class("b")
    assert_equal(%w[a b], h[:class])

    h = { a: 1, b: 2, class: ["a"] }
    h.add_class("b")
    assert_equal(%w[a b], h[:class])

    h = { a: 1, b: 2, class: ["a"] }
    h.add_class(["b", "c"])
    assert_equal(%w[a b c], h[:class])
  end

  def test_remove_class
    h = { a: 1, b: 2, class: %w[a b c] }
    h.remove_class("b")
    assert_equal(%w[a c], h[:class])
  end

  def test_deep_dup
    a = "abc"
    obj = [ { a: a, b: 2, c: 3 } ]
    new_obj = obj.deep_dup
    assert_equal(new_obj[0][:a], obj[0][:a])
    assert(new_obj[0][:a].object_id != obj[0][:a].object_id)
    a = "xyz"
    assert_equal("abc", new_obj[0][:a])
  end
end
