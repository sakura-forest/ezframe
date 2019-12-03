# frozen_string_literal: true

require_relative "../../pages/common.rb"
Dir["pages/*.rb"].each do |file|
  require_relative("../../#{file}")
end