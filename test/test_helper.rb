$:.push("./lib")
require "minitest/autorun"
require "ezframe"

ENV["RACK_ENV"] = "test"

class GenericTest < MiniTest::Test
  include Ezframe
end
