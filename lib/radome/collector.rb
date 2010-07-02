require 'socket'

require 'radome/data_store'

module Radome
  class Collector

    attr_accessor :metrics

    def initialize
      @metrics = DataStore.new({:type => :metrics})
    end

    def connection
      @connection ||= Excon.new('http://localhost:9292/')
    end

    def gossip(sensors=:recurring)
      sense(sensors)

      # find available local keys and sync this list with peer
      response = connection.request(:method => 'POST', :body => {'metrics' => @metrics.keys}.to_json)
      json = JSON.parse(response.body)

      # update local data from peer
      @metrics.update(json['metrics']['push'])

      # push requested updates to peer
      pull = {}
      for server_id, keys in json['metrics']['pull']
        pull[server_id] = @metrics.data[server_id].reject {|key,value| !keys.include?(key)}
      end
      connection.request(:method => 'PUT', :body => {'metrics' => pull}.to_json)
    end

    def run
      while true
        sense(:recurring)
        sleep(5)
      end
    end

    def sense(sensors=:recurring)
      new_data = {}
      for sensor in [*sensors]
        new_data.merge!(JSON.parse(`#{File.dirname(__FILE__)}/sensors/#{sensor}.rb`))
      end
      @metrics.update({
        Socket.gethostname => {
          Time.now.to_i.to_s => new_data
        }
      })
    end

  end
end
