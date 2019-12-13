# frozen_string_literal: true

require 'logger'
require 'rack'
require 'warden'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'ezframe'

use Rack::Session::Pool, secret: Digest::SHA256.hexdigest(rand.to_s)

use Rack::Static, urls: ['/image', '/js', '/css'], root: 'asset'
use Rack::ShowExceptions

run Ezframe::Server
