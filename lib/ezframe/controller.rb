# frozen_string_literal: true
module Ezframe
  class Controller
    attr_accessor :request, :response

    class Response
      attr_accessor :body, :status, :headers

      def initialize
        @headers = { "Content-Type" => "text/html" }
        @body = []
        @status = 200
      end

      def set_body_as_json(body)
        @headers["Content-Type"] = "application/json; charset=utf-8"
        @body = body
      end

      def []=(k, v)
        @headers[k] = v
      end

      def content_type=(v)
        @headers["Content-Type"] = v
      end

      def finish
        page_body = Array(@body)
        return [ @status, @headers, page_body]
      end
    end

    def initialize(req = nil, res = nil)
      @request, = req || Rack::Request.new
      @response = res || Response.new
      page_class, method, @route_params, class_opts = Route::choose(@request)

      EzLog.debug("Controller.exec: path=#{request_path}, params=#{req_params}, class=#{page_class}, method=#{method}, url_params=#{@query_params}, class_opts=#{class_opts}")
      if !page_class || page_class == 404
        file_not_found
        return
      end
      page_instance = page_class.new(self)
      @session = @request.env["rack.session"]
      @query_params = parse_query_string(env["QUERY_STRING"])
      if @request.content_type && @request.content_type.index("json")
        @json_body_params = parse_json_body(@request.body.read)
      end
      if class_opts
        opt_auth = class_opts[:auth]
        if !@session[:user] && Config[:auth] && (!opt_auth || opt_auth != "disable")
          EzLog.debug("authenticate!")
          warden.authenticate!
          EzLog.info "Controller.exec: warden.options = #{@request.env["warden.options"]}"
        end
      end
      body = page_instance.send(method)

      # 戻り値によるレスポンス生成
      if body.respond_to?(:to_ht)
        @response.body = [ Html.convert(body.to_ht) ]
      elsif body.is_a?(Hash) || body.is_a?(Array)
        # EzLog.debug("Controller: body = #{body}")
        json = JSON.generate(body)
        @response.body = [json]
        @response["Content-Type"] = "application/json; charset=utf-8"
      else
        @response.body = [body]
        @response["Content-Type"] = "text/html; charset=utf-8"
      end
      response.status = 200
    end

    def file_not_found
      @response.status = 404
      @response["Content-Type"] = "text/html; charset=utf-8"
      template_file = ("#{Config[:template_dir]}/404.html")
      # puts template_file
      if File.exist?(template_file)
        body = File.read(template_file)
      else
        body = Html.convert(Ht.p("file not found"))
      end
      @response.body = [body]
    end

    def request_method
      @request.request_method
    end

    def query_params
      @query_params
    end

    def req_params
      @request.params
    end

    def route_params
      @route_params
    end

    def json_body_params
      @json_body_params
    end

    def env
      @request.env
    end

    def body
      @request.body
    end

    def request_path
      @request.path_info
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
