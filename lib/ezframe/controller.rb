# frozen_string_literal: true

module Ezframe
  class Boot
    class << self
      def exec(request, response)
        mylog("exec: path=#{request.path_info} params=#{request.params}")
        Ezframe::Model.make_base
        model = Ezframe::Model.get_clone
        klass_name, method = parse_path(request.path_info)
        puts "klass_name, method = #{klass_name}, #{method}"
        klass = Ezframe::PageBase.get_class(klass_name)
        unless klass
          mylog("no such Ezframe class: #{klass_name}")
          page = Ezframe::Admin.new(request, model)
          response.body = [page.public_default_page ]
          response.status = 200
          return
        end
        page = klass.new(request, model)
        if request.post?
          method_full_name = "public_#{method}_post"
        else
          method_full_name = "public_#{method}_page"
        end

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
    end
  end
end
