# frozen_string_literal: true

require "logger"
require "rack"
require "rack-flash"
require "warden"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "ezframe"

use Warden::Manager do |manager|
  manager.default_strategies :mystrategy
  manager.failure_app = Proc.new do |env|
    ["401", { "Content-Type" => "text/html" }, [ Ezframe::App.new.public_login_page ]]
  end
end

use Rack::Session::Pool, secret: Digest::SHA256.hexdigest(rand.to_s)
use Rack::Static, urls: ["/image", "/js", "/css"], root: "asset"
use Rack::ShowExceptions
use Rack::Flash, :accessorize => [:notice, :error]

run Ezframe::Server
