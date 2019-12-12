# frozen_string_literal: true

if File.exist?("pages/common.rb")
  require "#{Dir.pwd}/pages/common.rb"
end
Dir["pages/*.rb"].each do |file|
  require "#{Dir.pwd}/#{file}"
end
