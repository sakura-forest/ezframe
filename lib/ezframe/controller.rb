# frozen_string_literal: true
module Ezframe
  class Controller
    class << self
      def init
        Config.init
        ColumnSets.init
        DB.init
        Message.init
        Auth.init if Config[:auth]
      end

      def exec(request, response)
        @request = request
        page_instance, method, url_params, class_opts = Route::choose(request)

        EzLog.debug("Controller.exec: path=#{request.path_info}, params=#{request.params}, class=#{page_instance.class}, method=#{method}, url_params=#{url_params}, class_opts=#{class_opts}")
        if !page_instance || page_instance == 404
          file_not_found(response)
          return
        end
        @request.env["url_params"] = url_params
        @session = @request.env['rack.session']
        if class_opts
          opt_auth = class_opts[:auth]
          if !@session[:user] && Config[:auth] && (!opt_auth || opt_auth != "disable")
            EzLog.debug("authenticate!")
            warden.authenticate! 
            EzLog.info "Controller.exec: warden.options = #{@request.env['warden.options']}"
          end
        end
        page_instance.set_request(@request)
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

      def warden
        @request.env["warden"]
      end

      def login?
        !!warden.user
      end

      def user
        warden.user
      end
    end
  end
end
