# frozen_string_literal: true

Dir["pages/*.rb"].each do |file|
  #require_relative("../../#{file}")
  require "#{Dir.pwd}/#{file}"
end
