# frozen_string_literal: true
require_relative "../test_helper.rb"

class ModelTest < GenericTest
  def test_model
    Model.init(columns_dir: "test/data", database: "sqlite://db/test.sqlite")
    model = Model.get_clone
    colset = model.column_sets[:sample]
    assert(colset)
    assert(colset[:v1])
    assert(colset[:v1].respond_to?(:value))
  end
end  
