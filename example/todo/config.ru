# frozen_string_literal: true

require 'logger'
require 'rack'
require 'warden'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'ezframe'
Dir["./config/*.rb"].each {|file| require file }

use Rack::Session::Cookie, :secret => 'kamasecret'

use Rack::Static, urls: ['/image', '/js', '/css'], root: 'asset'
use Rack::ShowExceptions

run Ezframe::Server
