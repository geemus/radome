require 'socket'

require 'radome/data_store'

module Radome
  class Collector

    attr_accessor :data_store

    def initialize
      @data_store = DataStore.new
    end

    def connection
      @connection ||= Excon.new('http://localhost:9292/')
    end

    def gossip(sensors=:recurring)
      sense(sensors)

      # find available local keys and sync this list with peer
      response = connection.request(:method => 'POST', :body => {'metrics' => @data_store.keys(:metrics)}.to_json)
      json = JSON.parse(response.body)

      # update local data from peer
      @data_store.update(:metrics, json['metrics']['push'])

      # push requested updates to peer
      pull = {}
      for server_id, keys in json['metrics']['pull']
        pull[server_id] = @data_store.data(:metrics)[server_id].reject {|key,value| !keys.include?(key)}
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
      @data_store.update(:metrics, { Socket.gethostname => { Time.now.to_i.to_s => new_data } })
    end

  end
end
