# frozen_string_literal: true
module Ezframe
  class Controller

    class Response
      attr_accessor :command_list, :body, :title, :status, :header, :set_history

      def initialize
        @status = 200
        @header = {}
      end

      def content_type=(v)
        @header["Content-Type"] = v
      end

      def add_command(command)
        @command_list ||= []
        @command_list.push(command)
      end

      def finish
        @command_list.push({ command: "set_history", url: @set_history, title: @title }) if @set_history
        @command_list.push({ command: "set_title", value: @title }) if @title
        # return [ @status, @header, Array(@body) ] if @status != 200
        body_tmp = nil
        if @body
          body_tmp = @body.respond_to?(:to_ht) ? @body.to_ht : @body
          body_tmp = Html.convert(body_tmp) unless body_tmp.is_a?(String)
        end
        # EzLog.debug("response.finish: command=#{@command}, body_tmp=#{body_tmp}")
        if @command_list
          add_command({ command: "set_body", body: body_tmp })
          body_tmp = JSON.generate(@command_list)
          @header["Content-Type"] = "application/json; charset=utf-8"
        else
          @header["Content-Type"] ||= "text/html; charset=utf-8"
        end
        res = [ @status, @header, [ body_tmp ] ]
        EzLog.debug("finish: res=#{res}")
        return res
      end

      def to_s
        return "status=#{@status}, title=#{@title}, command=#{@command}, body=#{@body}"
      end
    end

    attr_accessor :request, :response, :query_params, :json_body_params, :route_params, :class_opts

    def initialize(req = nil)
      @request = req || Rack::Request.new
      @response = Response.new
      @page_class, @method, @route_params, @class_opts = Route::choose(@request)
      @query_params = parse_query_string(env["QUERY_STRING"])
      EzLog.debug("Controller.initialize: xhr=#{@request.xhr?}, path=#{request_path}, params=#{request_params}, class=#{@page_class}, method=#{@method}, query_params=#{@query_params}, route_params=#{@route_params}, class_opts=#{@class_opts}")
      if @request.content_type && @request.content_type.index("json")
        @json_body_params = parse_json_body(@request.body.read)
      end
      if @class_opts
        opt_auth = @class_opts[:auth]
        if !session[:user] && Config[:auth] && (!opt_auth || opt_auth != "disable")
          EzLog.debug("authenticate!")
          warden.authenticate!
          EzLog.info "Controller.exec: warden.options = #{@request.env["warden.options"]}"
        end
      end
    end

    def execute
      if !@page_class || @page_class == 404
        file_not_found
      else
        @page_instance = @page_class.new(self)
        @page_instance.send(@method)
      end
      result = @response.finish
      # EzLog.debug("controller.execute:result=#{result}")
      EzLog.debug("controller.execute:result:result.status=#{@response.status}, command=#{@response.command_list.class}, body=#{result[2][0].to_s[0..80]} .....")
      return result
    end

    def file_not_found
      @response.status = 404
      @response.header["Content-Type"] ||= "text/html; charset=utf-8"
      template_file = ("#{Config[:template_dir]}/404.html")
      # puts template_file
      if File.exist?(template_file)
        body = File.read(template_file)
      else
        body = Html.convert(Ht.p("file not found"))
      end
      @response.body = body
    end

    def request_method
      @request.request_method
    end

    def request_params
      @request.params
    end

    def env
      @request.env
    end

    def session
      return @request.env['rack.session']
    end

    def request_body
      @request.body
    end

    def request_path
      @request.path_info
    end

    def ezevent
      if @json_body_params
        res = @json_body_params[:ezevent]
        return res if res
      end
      if @query_params
        res = @query_params[:ezevent]
        return res if res
      end
      return {}
    end

    def event_form
      ezevent[:form]
    end

    def warden
      @request.env["warden"]
    end

    def login?
      !!warden.user
    end

    def user
      warden.user
    end

    def parse_json_body(body)
      return {} if !body || body.length == 0
      begin
        json = JSON.parse(body, symbolize_names: true)
      rescue => e
        EzLog.info "no JSON body: #{e.class}:#{e.message}\n#{e.backtrace}"
        return nil
      end
      return json
    end
  end
end
