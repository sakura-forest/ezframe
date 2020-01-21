# frozen_string_literal: true

require "logger"
require "rack"
require "rack-flash"
require 'rack/session/redis'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "ezframe"

use Rack::Session::Pool
use Rack::Static, urls: ["/image", "/js", "/css"], root: "asset"
use Rack::ShowExceptions
use Rack::Flash, :accessorize => [:notice, :error]
run Ezframe::Server
