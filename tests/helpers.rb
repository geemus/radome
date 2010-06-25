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

def startup
  uname = `uname -a`
  os_name, hostname, os_release, os_version, architecture = uname.match(/^(\S*) (\S*) (\S*) (.*) (.*)$/).captures

  boottime = `sysctl kern.boottime`
  seconds, microseconds = boottime.match(/\{ sec = ([0-9]*), usec = ([0-9]*) \}/).captures
  system_boot_time = Time.at(seconds.to_i, microseconds.to_i).to_i

  system_time = `date +"%s"`.to_i

  {
    hostname => {
      Time.now.to_i => {
        :architecture     => architecture,
        :os => {
          :name     => os_name,
          :release  => os_release,
          :version  => os_version
        },
        :system_boot_time => system_boot_time,
        :system_time      => system_time
      }
    }
  }
end

def recurring
  hostname = `hostname`.chomp!

  uptime = `uptime`
  one_minute_load, five_minute_load, fifteen_minute_load = uptime.match(/load averages: ([\.0-9]*) ([\.0-9]*) ([\.0-9]*)/).captures

  system_time = `date +"%s"`.to_i

  {
    hostname => {
      Time.now.to_i => {
        :load => {
          :one_minute     => one_minute_load.to_f,
          :five_minute    => five_minute_load.to_f,
          :fifteen_minute => fifteen_minute_load.to_f
        },
        :system_time => system_time
      }
    }
  }
end

with_collector do

  p gossip(startup)
  # 3.times do
  #   pp put_data(recurring)
  #   sleep(1)
  # end
  # require 'pp'
  # pp get_data

end

#   p available_pairs(startup)
#   p available_pairs(recurring)
