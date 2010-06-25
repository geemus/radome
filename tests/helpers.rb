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

def gossip(data)
  # find available local keys and sync this list with peer
  keys = {}
  for server_id, datum in data
    keys[server_id] = datum.keys
  end
  response = connection.request(:method => 'POST', :body => keys.to_json)
  json = JSON.parse(response.body)
  # update local data from peer

  # push requested updates to peer
  pull = {}
  for server_id, keys in json['pull']
    pull[server_id] = data[server_id].reject {|key,value| !keys.include?(key)}
  end
  response = connection.request(:method => 'PUT', :body => pull.to_json)
end

def sense(sensors=:recurring)
  data = {}
  for sensor in [*sensors]
    data.merge!(JSON.parse(`#{File.dirname(__FILE__)}/../lib/radome/sensors/#{sensor}.rb`))
  end
  {
    `hostname`.chop! => {
      Time.now.to_i => data
    }
  }
end

# with_collector do
#
#   # p gossip(startup)
#   # 3.times do
#   #   pp put_data(recurring)
#   #   sleep(1)
#   # end
#   # require 'pp'
#   # pp get_data
#
# end
