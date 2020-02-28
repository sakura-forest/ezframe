# frozen_string_literal: true

require 'minitest/autorun'
require 'ezframe.rb'

class Request
  attr_accessor :path_info, :request_method
end

module Ezframe
  class Top < PageBase
    def public_default_get
    end
  end

  class Second < PageBase
    def public_default_get
    end

    def public_edit_get
    end
  end

  class Third < PageBase
    def public_default_get
    end
  end
end

class RouteTest < Minitest::Test
  def test_make_method_name
    assert_equal("public_foo_get", Ezframe::Route.make_method_name("foo", "GET"))
  end

  def test_choose
    route_h = { top: { second: { third: nil }}}

    req = Request.new
    req.request_method = "GET"
    req.path_info = "/top"
    res = Ezframe::Route.choose(req, route_h)
    assert(res.is_a?(Array))
    assert(res[0].instance_of?(Ezframe::Top))
    assert_equal("public_default_get", res[1])

    req.path_info = "/top/123/second/edit"
    res = Ezframe::Route.choose(req, route_h)
    assert(res.is_a?(Array))
    assert(res[0].instance_of?(Ezframe::Second))
    assert_equal("public_edit_get", res[1])
    assert_equal(res[2], { top: "123" })

    req.path_info = "/top/123/second/456/third/789"
    res = Ezframe::Route.choose(req, route_h)
    assert(res.is_a?(Array))
    # p res[0]
    assert(res[0].instance_of?(Ezframe::Third))
    assert_equal("public_default_get", res[1])
    assert_equal({top: "123", second: "456", third: "789"}, res[2])
  end

  def test_scan_path
    route_h = { top: { second: { third: nil }, v2: { fourth: nil }}}
    assert_equal([ :top, :second, :third ], Ezframe::Route.get_path(:third, route_h))
    assert_equal([ :top, :v2, :fourth ], Ezframe::Route.get_path(:fourth, route_h))
  end

  def test_scan_auth
    route_h = { top: { second: { third: nil }}}
    Ezframe::Top.auth = true
    assert_equal(Ezframe::Top, Ezframe::Route.scan_auth("third", route_h))
  end
end
