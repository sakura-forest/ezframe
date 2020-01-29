# frozen_string_literal: true

require "json"
require "uri"

require_relative "util"

module Ezframe
  class PageBase
    attr_accessor :auth

    def initialize(request = nil, model = nil)
      @model = model if model
      if request
        @request = request
        @params = parse_query_string(request.env["QUERY_STRING"])
        @params.update(request.params)
        mylog "params=#{@params.inspect}" if @params.length > 0
        @id, @key = @params[:id], @params[:key]
        @env = @request.env
        @session = @env["rack.session"]
        mylog "session = #{@session.inspect}"
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

    def common_get(opts = {})
      args = {
        title: opts[:title],
        body: opts[:body],
        into_html_header: Materialize.into_html_header,
        into_bottom_of_body: Materialize.into_bottom_of_body,
      }
      Template.fill("template/base.html", args)
    end

    def parse_json_body
      body = @request.body.read
      return {} if !body || body.length==0
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
