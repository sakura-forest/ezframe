# frozen_string_literal: true

if File.exist?("page/common.rb")
  require "#{Dir.pwd}/page/common.rb"
end
Dir["model/*.rb"].sort.each do |file|
  require "#{Dir.pwd}/#{file}"
end
Dir["page/*.rb"].sort.each do |file|
  require "#{Dir.pwd}/#{file}"
end
