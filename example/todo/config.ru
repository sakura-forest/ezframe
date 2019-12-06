# frozen_string_literal: true

require 'logger'
require 'rack'
#require 'rack/server'
#require 'rack/logger'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'ezframe'
Dir["./config/*.rb"].each {|file| require file }
# logger = ::Logger.new('log/app.log')

#def logger.write(msg)
#  self << msg
#end

use Rack::Static, urls: ['/image', '/js', '/css'], root: 'asset'
use Rack::ShowExceptions
# use Rack::CommonLogger, logger
run Ezframe::Server
