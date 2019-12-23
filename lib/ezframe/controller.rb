# frozen_string_literal: true

module Ezframe
  class Boot
    class << self
      def exec(request, response)
        @request = request
        Config.load_files("./config")
        Model.init
        model = Model.get_clone
        Auth.init_warden
        @request.env["model"] = model
        # Auth.model = model

        mylog("exec: path=#{request.path_info} params=#{request.params}")
        klass, method = PageBase::decide_route(request.path_info)
        page = klass.new(request, model)
        if request.post?
          method_full_name = "public_#{method}_post"
        else
          method_full_name = "public_#{method}_page"
        end
        if page.auth
          warden.authenticate! 
        end
        # request.env["rack.session"]["kamatest"]="usable"
        # mylog "method: #{klass}.#{method_full_name}"
        #mylog "rack.session.id=#{request.env['rack.session'].id}"
        #mylog "rack.session.keys=#{request.env['rack.session'].keys}"
        #mylog "warden=#{request.env['warden'].inspect}"
        mylog "klass=#{klass}, method=#{method_full_name}"
        body = if page.respond_to?(method_full_name)
                    page.send(method_full_name)
                  else
                    mylog "no such method: #{method_full_name}"
                    page.public_default_page
                  end
        if body.is_a?(Hash) || body.is_a?(Array)
          response.body = [ JSON.generate(body) ]
          response['Content-Type'] = 'application/json; charset=utf-8'
        else
          response.body = [ body ]
          response['Content-Type'] = 'text/html; charset=utf-8'
        end
        response.status = 200
      end

#      def file_not_found(response)
#        response.body = ['path not found']
#        response.status = 404
#      end

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
