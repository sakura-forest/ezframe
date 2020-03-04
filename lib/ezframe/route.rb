module Ezframe
  class Route
    class << self
      def choose(request, route_h = nil)
        path_parts = request.path_info.split("/").drop(1)
        route_h ||= Config[:route].deep_dup
        # puts  "config=#{Config[:route]}, route_h=#{route_h}"
        args = {}
        class_a = []
        # p path_parts
        if path_parts.empty?
          root_conf = route_h[:/]
          # p root_conf
          if root_conf
            klass = get_class(root_conf[:class])
            return [ klass.new, make_method_name("default", request.request_method) ]
          end
          return [ 404 ]
        end
        # URLを解析して、クラスの決定とIDの取得を行う
        while path_parts.length > 0
          part = path_parts.shift
          # break if part.empty?
          # mylog "part=#{part}, route_h=#{route_h.inspect}"
          if route_h.has_key?(part.to_sym)
            # mylog "has_route: #{part}"
            class_a.push(part)
            if path_parts[0].to_i > 0
              args[part.to_sym] = val = path_parts.shift
              # mylog "value: part=#{part}, val=#{val}"
            end
            route_h = route_h[part.to_sym]
            break if route_h.nil?
            # mylog "route_h changed: #{route_h}"
          else
            # routeに無ければ、メソッドを探す
            # mylog "no_route: #{part}"
            klass = get_class(class_a[-1])
            return [ 404 ] unless klass
            instance = klass.new
            method_name = make_method_name(part, request.request_method)
            if instance.respond_to?(method_name)
              return [instance, method_name, args]
            else
              mylog "undefined method: #{klass}.#{method_name}: full path=#{request.path_info}"
            end
          end
        end
        # 最後にメソッド名が無い場合はpublic_default_#{method}を実行。
        #puts "class_a=#{class_a}"
        klass = get_class(class_a[-1])
        return [404] unless klass
        if path_parts.length > 0
          part = path_parts.shift
        else
          part = "default"
        end
        method_name = make_method_name(part, request.request_method)
        #mylog "method_name=#{method_name}"
        instance = klass.new
        if instance.respond_to?(method_name)
          return [instance, method_name, args]
        end
        return [ 404 ]
      end

      # ページクラスの階層を辿る
      def get_path(class_snake, route_h = nil)
        route_h = Config[:route] unless route_h
        # mylog "get_path: route_h=#{route_h}"
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
            next if k == :class
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

      # 認証を行うクラスを返す。無ければnil
=begin
      def scan_auth(target, route_h = nil)
        target = class_to_snake(target) if target.is_a?(Class)
        path = get_path(target, route_h)
        mylog "scan_auth: target=#{target} path=#{path}"
        return nil unless path
        path.each do |class_snake|
          klass = get_class([class_snake])
          puts "path: klass = #{klass}"
          return klass if klass.need_auth
        end
        return nil
      end
=end      

      def make_method_name(base_name, method = "get")
        return ["public", base_name, method.downcase].join("_")
      end

      def get_class(keys)
        # mylog "get_class: #{keys.inspect}"
        return nil unless keys
        keys = [ keys ] if keys.is_a?(String)
        klass = (%w[Ezframe] + keys.map { |k| k.to_s.to_camel }).join("::")
        # mylog "get_class: #{klass}"
        if Object.const_defined?(klass)
          return Object.const_get(klass)
        else
          raise "get_class: undefined class: #{klass}"
        end
        return nil
      end
    end
  end
end
