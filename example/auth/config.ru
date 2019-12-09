# frozen_string_literal: true

require "logger"
require "rack"
require "warden"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "ezframe"

failure_app = Proc.new do |env|
  ["401", { "Content-Type" => "text/html" }, ["fail."]]
end

use Warden::Manager do |manager|
  manager.default_strategies :base
  manager.failure_app = failure_app
end

use Rack::Session::Cookie, :secret => "kamasecret"

use Rack::Static, urls: ["/image", "/js", "/css"], root: "asset"
use Rack::ShowExceptions

run Ezframe::Server
