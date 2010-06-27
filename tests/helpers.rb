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

@data = DataStore.new(Thread.current[:data])

def gossip(sensors=:recurring)
  sense(sensors)
  # find available local keys and sync this list with peer
  response = connection.request(:method => 'POST', :body => @data.keys.to_json)
  json = JSON.parse(response.body)
  # update local data from peer
  p json['push']

  # push requested updates to peer
  pull = {}
  for server_id, keys in json['pull']
    pull[server_id] = @data.data[server_id].reject {|key,value| !keys.include?(key)}
  end
  connection.request(:method => 'PUT', :body => pull.to_json)
end

def sense(sensors=:recurring)
  new_data = {}
  for sensor in [*sensors]
    new_data.merge!(JSON.parse(`#{File.dirname(__FILE__)}/../lib/radome/sensors/#{sensor}.rb`))
  end
  @data.update({
    `hostname`.chop! => {
      Time.now.to_i => new_data
    }
  })
end

with_collector do
  p gossip([:recurring, :startup])
  3.times do
    sleep(1)
    p gossip
  end
  require 'pp'
  p 'local'
  pp @data.data
  p 'remote'
  pp get_data
end
