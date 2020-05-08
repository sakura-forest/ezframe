# frozen_string_literal: true

module Ezframe
  class Server
    def initialize
      Controller.init
    end

    def call(env)
      req = Rack::Request.new(env)
      res = Rack::Response.new
      begin
        Controller.exec(req, res)
      rescue => e
        EzLog.error("Controller.exec: exception: #{e.message}:\n#{e.backtrace}")
        res.status = 500
        res.headers["Content-Type"] = "text/plain"
        res.body = [ "Internal server error" ]
      end
#      if res.body.empty?
#        raise "no body in response"
#      end
      return res.finish
    end
  end
end