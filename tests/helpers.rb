require File.join(File.dirname(__FILE__), '..', 'lib', 'radome')
require 'excon'

def start_collector
  @collector ||= begin
    collector = Thread.new { Rack::Handler::WEBrick.run(Radome::Collector.new, :Port => 9292, :AccessLog => [], :Logger => WEBrick::Log.new(nil, WEBrick::Log::ERROR)) }
    sleep(1)
    collector
  end
end

def stop_collector
  @collector && @collector.exit
end

def with_collector(&block)
  start_collector
  yield
  stop_collector
end

def connection
  @connection ||= Excon.new('http://localhost:9292/')
end

def get_data
  data = connection.request(:method => 'GET').body
  JSON.parse(data)
end

def put_data(new_data)
  data = connection.request(:method => 'PUT', :body => new_data.to_json).body
  JSON.parse(data)
end

with_collector do

  p get_data
  p put_data({'a' => 'b'})
  p put_data({'c' => 'd'})
  p put_data({'a' => 'c'})

end