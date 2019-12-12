# frozen_string_literal: true

require "json"
require "uri"

require_relative "util"

module Ezframe
  class PageBase
    class << self
      def get_class(keys)
        keys = [keys] if keys.is_a?(String)
        klass = (%w[Ezframe] + keys.map { |k| k.to_camel }).join("::")
        if Object.const_defined?(klass)
          return Object.const_get(klass)
        end
        return nil
      end

      def decide_route(path_info)
        default_class = Config[:default_page_class]||"App"
        default_method = Config[:default_page_method]||"default"
        path_parts = path_info.split('/').drop(1)
        case path_parts.length
        when 0
          [get_class(default_class), default_method]
        when 1
          klass = get_class(path_parts)
          if klass
            return [klass, default_method]
          else
            return [get_class(default_class), parth_parts[0]]
          end
        else
          klass = get_class(path_parts)
          if klass
            [klass, default_method]
          else
            method = path_parts.pop
            klass = get_class(path_parts)
            [klass, method]
          end
        end
      end
    end

    attr_accessor :auth

    def initialize(request = nil, model = nil)
      @model = model if model
      if request
        @request = request
        @params = parse_query_string(request.env["QUERY_STRING"])
        @params.update(request.params)
        mylog "params=#{@params.inspect}" if @params.length > 0
        @id, @key = @params[:id], @params[:key]
        if request.post?
          parse_json_body
          mylog "json=#{@json.inspect}"
        end
      end
      @auth = nil
    end

    def parse_query_string(str)
      query_a = URI::decode_www_form(str)
      res_h = {}
      query_a.map { |a| res_h[a[0].to_sym] = a[1] }
      res_h
    end

    def common_page(opts = {})
      args = {
        title: opts[:title],
        body: opts[:body],
        into_html_header: Materialize.into_html_header,
        into_bottom_of_body: Materialize.into_bottom_of_body,
      }
      EzView::Template.fill_template("template/base.html", args)
    end

    def parse_json_body
      body = @request.body.read
      begin
        @json = JSON.parse(body)
      rescue => e
        mylog "ERROR: #{e.class}:#{e.message}\n#{e.backtrace}"
        return nil
      end
      @json = @json.recursively_symbolize_keys if @json.is_a?(Hash) || @json.is_a?(Array)
      return @json
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
