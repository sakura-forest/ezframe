# frozen_string_literal: true

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