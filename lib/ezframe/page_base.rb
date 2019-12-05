# frozen_string_literal: true

require "json"
require "uri"

require_relative 'util'

module Ezframe
  class PageBase
    def self.get_class(keys)
      keys = [ keys ] if keys.is_a?(String)
      klass = (%w[Ezframe] + keys.map {|k| k.to_camel }).join("::")
      if Object.const_defined?(klass)
        return Object.const_get(klass)
      end
      return nil
    end

    def initialize(request, model)
      @model = model # EzModel::Bridge.instance
      @request = request
      @params = parse_query_string(request.env["QUERY_STRING"])
      @id, @key = @params[:id], @params[:key]
      parse_json_body if request.post?
    end  

    def parse_query_string(str)
      query_a = URI::decode_www_form(str)
      res_h = {}
      query_a.map {|a| res_h[a[0].intern] = a[1] }
      res_h
    end

    def common_page(opts = {})
      args = {
        title: opts[:title],
        body: opts[:body],
        into_html_header: Materialize.into_html_header,
        into_bottom_of_body: Materialize.into_bottom_of_body
      }
      EzView::Template.fill_template('template/base.html', args)
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

    def main_layout(left: "Logo", center: "", right: "")
      { tag: "div", class: ["row", "container"], child: [
        { tag: "div", class: %w[col s3], id: "left", child: left },
        { tag: "div", class: %w[col s5], id: "center-panel", child: center },
        { tag: "div", class: %w[col s4], id: "right-panel", child: right }
      ] }
    end
  end
end
