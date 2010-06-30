require File.join(File.dirname(__FILE__), '..', 'lib', 'radome')
require 'excon'

def with_collector(&block)
  collector = Thread.new do
    Rack::Handler::WEBrick.run(
      Radome::Collector.new,
      :Port => 9292,
      :AccessLog => [],
      :Logger => WEBrick::Log.new(nil, WEBrick::Log::ERROR)
    )
  end
  sleep(1)
  yield
  collector.exit
end

def connection
  @connection ||= Excon.new('http://localhost:9292/')
end

def get_data
  data = connection.request(:method => 'GET').body
  JSON.parse(data)
end

sensor = Sensor.new

with_collector do
  connection.request(:method => 'PUT', :body => {'fake' => {'123456789' => {'a' => 'b'}}}.to_json)
  p sensor.gossip([:recurring, :startup])
  3.times do
    sleep(1)
    p sensor.gossip
  end
  require 'pp'
  p 'local'
  pp sensor.data
  p 'remote'
  pp get_data
  p sensor.data == get_data
end
