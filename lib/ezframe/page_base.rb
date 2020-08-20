# frozen_string_literal: true

require "json"
require "uri"
require_relative "util"

module Ezframe
  class PageBase
    attr_accessor :controller, :column_set, :dataset, :index_keys

    def initialize(cntl)
      @controller = cntl
      @class_snake = class_to_snake(self.class)
      # puts "class_snake = #{@class_snake}"
      @request, @response = @controller.request, @controller.response
      init_var
    end

    def init_var
      @column_set = ColumnSets.get(@class_snake)
      @dataset = DB.dataset(@class_snake) if @column_set
    end

    # routeから基本URLを生成
    def make_base_url(id = nil)
      path = Route::get_path(@class_snake)
      params = @controller.route_params || {}
      # EzLog.info "make_base_url: params=#{params}"
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
      # EzLog.info "path_s=#{path_s}"
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
