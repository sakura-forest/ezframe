# frozen_string_literal: true

require 'logger'
require 'rack'
require 'rack/server'
require 'rack/logger'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'ezframe'

module Ezframe
  class Server
    def self.call(env)
      req = Rack::Request.new(env)
      res = Rack::Response.new
      Boot.exec(req, res)
      if res.body.empty?
        raise "no body in response"
      end
      res.finish
    end
  end
end

logger = ::Logger.new('log/app.log')

def logger.write(msg)
  self << msg
end

use Rack::Static, urls: ['/image', '/js', '/css'], root: 'asset'
use Rack::ShowExceptions
use Rack::CommonLogger, logger
run Ezframe::Server
