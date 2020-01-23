# frozen_string_literal: true

require "logger"
require "rack"
require "ezframe"

use Rack::Session::Pool
use Rack::Static, urls: ["/image", "/js", "/css"], root: "asset"
use Rack::ShowExceptions
run Ezframe::Server
