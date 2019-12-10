# frozen_string_literal: true

module Ezframe
  class Boot
    class << self
      def exec(request, response)
        @request = request
        Config.load_files("./config")
        mylog("exec: path=#{request.path_info} params=#{request.params}")
        Model.init
        model = Model.get_clone
        Auth.init_warden
        Auth.model = model
#        if "/unauthorized" == request.path_info
#          response.body= [ App.new(request, model).public_login_page ]
#          response.status = 200
#          return
#        end
#        warden.authenticate!
#        mylog "authed: #{warden.user.inspect}"
        klass_names = parse_path(request.path_info)
        mylog "klass_names=#{klass_names}"
        if klass_names.empty?
          klass_names =  [ Config[:default_page_class] ]
        elsif klass_names.length > 1
          method = klass_names.pop
        else
          method = "default"
        end
        klass = PageBase.get_class(klass_names)
        unless klass
          mylog("no such Ezframe class: #{klass_names}")
          fallback = "Ezframe::#{Config[:default_page_class]}"
          mylog("fallback=#{fallback}")
          klass = Object.const_get(fallback)
          page = klass.new(request, model)
          response.body = [ page.public_default_page ]
          response.status = 200
          return
        end
        mylog "klass=#{klass}"
        page = klass.new(request, model)
        if request.post?
          method_full_name = "public_#{method}_post"
        else
          method_full_name = "public_#{method}_page"
        end
        warden.authenticate! if page.auth
        request.env["rack.session"]["kamatest"]="kamatest1234"
        mylog "method: #{klass}.#{method_full_name}"
        mylog "rack.session.id=#{request.env['rack.session'].id}"
        mylog "rack.session.keys=#{request.env['rack.session'].keys}"
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

      def parse_path(path_info)
        path_a = path_info.split('/').drop(1)
        return path_a
      end

      def file_not_found(response)
        response.body = ['path not found']
        response.status = 404
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
