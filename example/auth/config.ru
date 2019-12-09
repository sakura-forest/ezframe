# frozen_string_literal: true

require 'logger'
require 'rack'
require 'warden'
#require 'rack/server'
#require 'rack/logger'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'ezframe'
Dir["./config/*.rb"].each {|file| require file }
# logger = ::Logger.new('log/app.log')

#def logger.write(msg)
#  self << msg
#end

failure_app = Proc.new do |env|
    ['401', {'Content-Type' => 'text/html'}, ['fail.']]
end
use Warden::Manager do |manager|
  manager.default_strategies :password
  manager.failure_app = failure_app
end

use Rack::Session::Cookie, :secret => 'kamasecret'

use Rack::Static, urls: ['/image', '/js', '/css'], root: 'asset'
use Rack::ShowExceptions
# use Rack::CommonLogger, logger

Warden::Manager.serialize_into_session do |user|
  user.id
end

Warden::Manager.serialize_from_session do |id|
  User.get(id)
end

Warden::Strategies.add(:password) do
  def valid?
    params['id'] || params['password']
  end

  def authenticate!
    mylog "id, pass=#{params.inspect}"
    if User.authenticate(params['id'], params['password'])
      success! User.get(params['id'])
    else
      fail!('failll')
    end
  end
end

run Ezframe::Server
