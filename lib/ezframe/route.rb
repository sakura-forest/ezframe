module Ezframe
  class Route
    class << self
      def choose(request, route_h = nil)
        path_parts = request.path_info.split("/").drop(1)
        route_h ||= Config[:route].deep_dup
        unless route_h
          raise "Config[:route] is not defined. It should be defined in config/route.yml"
        end
        # puts  "config=#{Config[:route]}, route_h=#{route_h}"
        args = {}
        opts = {}
        class_a = []
        if path_parts.empty?
          root_conf = route_h[:/]
          if root_conf
            klass = get_class(root_conf[:class])
            return [ klass.new, make_method_name("default", request.request_method) ]
          end
          return [ 404 ]
        end
        # URLを解析して、クラスの決定とIDの取得を行う
        while path_parts.length > 0
          part = path_parts.shift
          if route_h.has_key?(part.to_sym)
            class_a.push(part)
            if path_parts[0].to_i > 0
              args[part.to_sym] = val = path_parts.shift
            end
            route_h = route_h[part.to_sym]
            break if route_h.nil?
            opts = {}
            route_h.keys.compact.each do |rkey|
              if rkey =~ /option_(\w+)/
                opt_key = $1
                opts[opt_key.to_sym] = route_h[rkey]
              end
            end
          else
            # routeに無ければ、メソッドを探す
            klass = get_class(class_a[-1])
            return [ 404 ] unless klass
            # instance = klass.new
            method_name = make_method_name(part, request.request_method)
            return [klass, method_name, args, opts]
            # if instance.respond_to?(method_name)
            #else
            #  EzLog.error "undefined method: #{klass}.#{method_name}: full path=#{request.path_info}"
            #end
          end
        end
        # 最後にメソッド名が無い場合はpublic_default_#{method}を実行。
        klass = get_class(class_a[-1])
        return [404] unless klass
        if path_parts.length > 0
          part = path_parts.shift
        else
          part = "default"
        end
        method_name = make_method_name(part, request.request_method)
#        instance = klass.new
#        if instance.respond_to?(method_name)
        return [ klass, method_name, args, opts]
#        end
#        return [ 404 ]
      end

      # ページクラスの階層を辿る
      def get_path(class_snake, route_h = nil)
        route_h = Config[:route] unless route_h
        @get_path_found_it = nil
        route =_scan_route(class_snake, route_h.deep_dup) 
        return route.reverse if route
        return nil
      end

      # targetに対応する名称のクラスまでの経路を返す
      def _scan_route(target, route_h)
        if route_h.keys.include?(target.to_sym)
          @get_path_found_it = true
          return [ target ]
        else
          route_h.each do |k, v|
            next if k.to_s =~ /^option_/
            if v.is_a?(Hash)
              a = _scan_route(target, v)
              if @get_path_found_it
                a.push(k)
                return a
              end
            end
          end
        end
        return nil
      end

      def make_method_name(base_name, method = "get")
        return ["public", base_name, method.downcase].join("_")
      end

      def get_class(keys)
        return nil unless keys
        keys = [ keys ] if keys.is_a?(String)
        klass = (%w[EzPage] + keys.map { |k| k.to_s.to_camel }).join("::")
        if Object.const_defined?(klass)
          return Object.const_get(klass)
        else
          raise "get_class: undefined class: #{klass}"
        end
      end
    end
  end
end
