module Ezframe
  class Route
    class << self
      def choose(request, route_h = nil)
        path_parts = request.path_info.split("/").drop(1)
        route_h = Config[:route] unless route_h
        class_a = []
        args = {}
        # URLを解析して、クラスの決定とIDの取得を行う
        while path_parts.length > 0
          part = path_parts.shift
          # break if part.empty?
          puts "part=#{part}, route_h=#{route_h.inspect}"
          if route_h.has_key?(part.to_sym)
            puts "has_route: #{part}"
            class_a.push(part)
            if path_parts[0].to_i > 0
              args[part.to_sym] = path_parts.shift
            end
            route_h = route_h[part.to_sym]
            puts "route_h changed: #{route_h}"
          else
            # routeに無ければ、メソッドを探す
            puts "no_route: #{part}"
            klass = get_class(class_a[-1])
            instance = klass.new
            method_name = make_method_name(part, request.request_method)
            if instance.respond_to?(method_name)
              return [instance, method_name, args]
            else
              mylog "undefined method: #{method_name}: full path=#{request.path_info}"
            end
          end
        end
        # 最後にメソッド名が無い場合はpublic_default_#{method}を実行。
        # p class_a
        klass = get_class(class_a[-1])
        method_name = make_method_name("default", request.request_method)
        instance = klass.new
        if instance.respond_to?(method_name)
          return [instance, method_name, args]
        end
        return 404
      end

      def make_method_name(base_name, method)
        return ["public", base_name, method.downcase].join("_")
      end

      def get_class(keys)
        puts "get_class: #{keys.inspect}"
        return nil unless keys
        keys = [keys] if keys.is_a?(String)
        klass = (%w[Ezframe] + keys.map { |k| k.to_camel }).join("::")
        mylog "get_class: #{klass}"
        if Object.const_defined?(klass)
          return Object.const_get(klass)
        end
        return nil
      end

      def find_file(target)
        Find.find("./asset").each do |file|
          path_a = file.split("/")
          if path_a[-1] == target
            suffix = "." + target.split(".")[-1]
            return [200, { "Content-Type" => Rack::Mime.mime_type(suffix) }, [File.open(file, &:read)]]
          end
        end
        return 404
      end
    end
  end
end
