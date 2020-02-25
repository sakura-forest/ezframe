# frozen_string_literal: true

module Ezframe
  class Server
    def initialize
      Controller.init
    end

    def call(env)
      req = Rack::Request.new(env)
      res = Rack::Response.new
      Controller.exec(req, res)
      if res.body.empty?
        raise "no body in response"
      end
      return res.finish
    end
  end
end