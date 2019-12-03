# frozen_string_literal: true

require 'minitest/autorun'
require 'lib/page.rb'

class MaterializeTest < Minitest::Test
  include EzPage

  def test_dict
    assert_equal(Registration, PageBase.get_class("registration"))
  end
end

