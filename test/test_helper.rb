$:.unshift("./lib")
require "minitest/autorun"
require "ezframe"

class GenericTest < MiniTest::Test
  include Ezframe
end
