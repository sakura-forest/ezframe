# frozen_string_literal: true

module Ezframe
  class Controller
    class << self
      def init
        Config.load_files("./config")
        Model.init
        Message.init
        Auth.init_warden if defined?(Warden)
      end

      def exec(request, response)
        @request = request
        model = Model.get_clone
        @request.env["model"] = model

        mylog("exec: path=#{request.path_info} params=#{request.params}")
        page_instance, method, url_params = Route::choose(request)
        mylog "page: #{page_instance.class}, method=#{method}, url_params=#{url_params}"
        if !page_instance || page_instance == 404
          file_not_found(response)
          return
        end
        @request.env["url_params"] = url_params
        warden.authenticate! if page_instance.auth
        mylog "rack.session.keys=#{request.env['rack.session'].keys}"
        page_instance.set_request(@request)
        body = page_instance.send(method)

        # 戻り値によるレスポンス生成
        if body.is_a?(Hash) || body.is_a?(Array)
          response.body = [ JSON.generate(body) ]
          response['Content-Type'] = 'application/json; charset=utf-8'
        else
          response.body = [ body ]
          response['Content-Type'] = 'text/html; charset=utf-8'
        end
        response.status = 200
        p response.body
      end

      def file_not_found(response)
        response.status = 404
        response['Content-Type'] = 'text/html; charset=utf-8'
        template_file = ("#{Config[:template_dir]}/404.html")
        puts template_file
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
