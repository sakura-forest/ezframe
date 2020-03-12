# frozen_string_literal: true

require "json"
require "uri"
require_relative "util"

module Ezframe
  class PageBase
    class << self
      attr_accessor :auth
    end
    
    attr_accessor :request

    def initialize(request = nil)
      @class_snake = class_to_snake(self.class)
      # puts "class_snake = #{@class_snake}"
      set_request(request) if request
      init_vars
    end

    def init_vars
    end

    # Rackのrequestを代入し、関連するインスタンス変数を定義
    def set_request(request)
      @request = request
      @model = request[:model]
      @model = request[:model] = Model.get_clone unless @model
      @column_set = @model.column_sets[@class_snake.to_sym]
      mylog "[WARN] column_set is not defined: #{@class_snake}" unless @column_set
      if @column_set
        @dataset = @column_set.dataset if @column_set
      end
      @params = parse_query_string(request.env["QUERY_STRING"])
      @params.update(request.params)
      # mylog "set_request: params=#{@params.inspect}" if @params.length > 0
      # @id, @key = @params[:id], @params[:key]
      @env = @request.env
      @session = @env["rack.session"]
      # mylog "session = #{@session.inspect}"
      if %w[POST PUT].include?(request.request_method)
        body = @request.body.read
        if request.content_type.index("json")
          @parsed_body = parse_json_body(body)
        else
          @parsed_body = parse_query_string(body)
        end
        # mylog "parsed_body=#{@parsed_body.inspect}"
        @event = @parsed_body[:event] || {}
        # mylog "event=#{@event}"
      end
    end

    # routeから基本URLを生成
    def make_base_url(id = nil)
      path = Route::get_path(@class_snake)
      params = @request.env["url_params"]
      # mylog "make_base_url: params=#{params}"
      # params[@class_snake.to_sym] = id
      path_s = path.map do |pa|
        if pa == @class_snake.to_sym && id
          "#{pa}/#{id}"
        elsif params[pa.to_sym]
          "#{pa}/#{params[pa.to_sym]}"
        else
          pa
        end
      end.join("/")
      # mylog "path_s=#{path_s}"
      return "/#{path_s}"
    end

    def show_base_template(opts = {})
      args = {
        title: opts[:title],
        body: opts[:body],
        into_html_header: Materialize.into_html_header,
        into_bottom_of_body: Materialize.into_bottom_of_body,
      }
      Template.fill_from_file("template/base.html", args)
    end

    def parse_json_body(body)
      return {} if !body || body.length==0
      begin
        json = JSON.parse(body)
      rescue => e
        mylog "ERROR: #{e.class}:#{e.message}\n#{e.backtrace}"
        return nil
      end
      json = json.recursively_symbolize_keys if json.is_a?(Hash) || json.is_a?(Array)
      return json
    end

    def session
      return @request.env['rack.session']
    end

    def warden
      return @request.env["warden"]
    end

    def login?
      !!warden.user
    end

    def user
      return warden.user
    end
  end
end
