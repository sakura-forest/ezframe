$:.push("./lib")
require "minitest/autorun"
require "ezframe"

ENV["RACK_ENV"] = "test"

def init_test_db(test_db_file = nil)
  test_db_file ||= "db/test.sqlite"
  File.unlink(test_db_file) if File.exist?(test_db_file)
  Ezframe::DB.init("sqlite://#{test_db_file}")
end

class GenericTest < MiniTest::Test
  include Ezframe
end
