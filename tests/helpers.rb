require File.join(File.dirname(__FILE__), '..', 'lib', 'radome')
require 'excon'

def with_server(&block)
  server = Thread.new do
    Rack::Handler::WEBrick.run(
      Radome::Server.new,
      :Port => 9292,
      :AccessLog => [],
      :Logger => WEBrick::Log.new(nil, WEBrick::Log::ERROR)
    )
  end
  sleep(1)
  yield
  server.exit
end

def connection
  @connection ||= Excon.new('http://localhost:9292/')
end

def get_data
  data = connection.request(:method => 'GET').body
  JSON.parse(data)
end

collector = Radome::Collector.new

with_server do
  connection.request(:method => 'PUT', :body => {'fake' => {'123456789' => {'a' => 'b'}}}.to_json)
  p collector.gossip([:recurring, :startup])
  3.times do
    sleep(1)
    p collector.gossip
  end
  require 'pp'
  p 'local'
  pp collector.data
  p 'remote'
  pp get_data
  p collector.data == get_data
end
