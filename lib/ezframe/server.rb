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
      begin
        ctrl = Controller.new(req)
        res = ctrl.execute
        raise "response body is not a string: class=#{res[2][0].class}, body=#{res[2][0]}" unless res[2][0].is_a?(String)
        return res
      rescue => e
        EzLog.error("Controller.exec: exception: #{e.message}:\n#{e.backtrace}")
        return [ 500, { "Content-Type" => "text/plain" }, [ "Internal server error" ] ]
      end
    end
  end
end