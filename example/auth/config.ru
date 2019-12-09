# frozen_string_literal: true

require "logger"
require "rack"
require "warden"
require "digest/sha1"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "ezframe"

failure_app = Proc.new do |env|
  ["401", { "Content-Type" => "text/html" }, ["fail."]]
end

use Warden::Manager do |manager|
  manager.default_strategies :mystrategy
  manager.failure_app = failure_app
end

use Rack::Session::Pool, secret: Digest::SHA256.hexdigest(rand.to_s)
use Rack::Static, urls: ["/image", "/js", "/css"], root: "asset"
use Rack::ShowExceptions

run Ezframe::Server
