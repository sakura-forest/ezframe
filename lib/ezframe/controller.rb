# frozen_string_literal: true
module Ezframe
  class Controller
    class << self
      def init
        Config.init
        ColumnSets.init
        DB.init
        Message.init
        Auth.init(self) if Config[:auth]
      end

      def exec(request, response)
        @request = request
        page_instance, method, @route_params, class_opts = Route::choose(request)

        EzLog.debug("Controller.exec: path=#{request_path}, params=#{req_params}, class=#{page_instance.class}, method=#{method}, url_params=#{url_params}, class_opts=#{class_opts}")
        if !page_instance || page_instance == 404
          find_template(request)
          file_not_found(response)
          return
        end
        page_instance.controller = self
        # env["route_params"] = @route_params
        @session = @request.env['rack.session']
        @query_params = parse_query_string(env["QUERY_STRING"])
        if request.content_type.index("json")
          @json_body_params = parse_json_body(@request.body.read)
        end
        if class_opts
          opt_auth = class_opts[:auth]
          if !session[:user] && Config[:auth] && (!opt_auth || opt_auth != "disable")
            EzLog.debug("authenticate!")
            warden.authenticate! 
            EzLog.info "Controller.exec: warden.options = #{@request.env['warden.options']}"
          end
        end
        # page_instance.set_request(@request)
        body = page_instance.send(method)

        # 戻り値によるレスポンス生成
        if body.is_a?(Hash) || body.is_a?(Array)
          # EzLog.debug("Controller: body = #{body}")
          json = JSON.generate(body)
          response.body = [ json ]
          response['Content-Type'] = 'application/json; charset=utf-8'
        else
          response.body = [ body ]
          response['Content-Type'] = 'text/html; charset=utf-8'
        end
        response.status = 200
      end

      def file_not_found(response)
        response.status = 404
        response['Content-Type'] = 'text/html; charset=utf-8'
        template_file = ("#{Config[:template_dir]}/404.html")
        # puts template_file
        if File.exist?(template_file) 
          body = File.read(template_file)
        else
          body = Html.convert(Ht.p("file not found"))
        end
        response.body = [ body ]
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
        return {} if !body || body.length==0
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
end
