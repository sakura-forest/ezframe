# frozen_string_literal: true

module Ezframe
  class Server
    def initialize
      Config.init
      ColumnSets.init
      DB.init
      Message.init
      Auth.init if Config[:auth]
    end

    def call(env)
      req = Rack::Request.new(env)
      res = Controller::Response.new
      begin
        Controller.new(req, res)
      rescue => e
        EzLog.error("Controller.exec: exception: #{e.message}:\n#{e.backtrace}")
        res.status = 500
        res.headers["Content-Type"] = "text/plain"
        res.body = [ "Internal server error" ]
      end
      return res.finish
    end
  end
end