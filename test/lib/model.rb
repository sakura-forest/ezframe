# frozen_string_literal: true

require "minitest/autorun"
require "lib/ezframe.rb"

class ModelTest < Minitest::Test
  def test_model
    model = EzModel::Bridge.instance
    p model.column_sets
    colset = model.column_sets[:customer]
    assert(colset)
    assert(colset[:email])
    assert(colset[:email].respond_to?(:value))
  end
end  
