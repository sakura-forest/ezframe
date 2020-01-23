#!/usr/bin/env ruby
#coding: utf-8
=begin

  アプリケーションテンプレートの生成

=end
require "fileutils"

target_dir = ARGV[0]

unless File.exist?(target_dir)
  Dir.mkdir(target_dir)
end
FileUtils.cp_r("app_template", target_dir)