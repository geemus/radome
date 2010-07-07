require File.join(File.dirname(__FILE__), '..', 'lib', 'radome')
require 'excon'

def with_server(&block)
  pid = Process.fork do
    Rack::Handler::WEBrick.run(
      Radome::Server.new,
      :Port => 9292,
      :AccessLog => [],
      :Logger => WEBrick::Log.new(nil, WEBrick::Log::ERROR)
    )
  end
  sleep(1)
  yield
  Process.kill(9, pid)
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
  datum = {Time.now.to_i.to_s => {'a' => 'b'}}
  connection.request(:method => 'PUT', :body => {
    'metrics' => {'remote' => datum}
  }.to_json)
  collector.data_store.update({'metrics' => {'local' => datum}})
  collector.data_store.update({'config' => {'peers' => {Time.now.to_i.to_s => ['http://localhost:9292/']}}})
  3.times do
    sleep(1)
    p collector.gossip
  end
  require 'pp'
  p 'local'
  pp JSON.parse(collector.data_store.data)
  p 'remote'
  pp get_data
  p JSON.parse(collector.data_store.data) == get_data
end
