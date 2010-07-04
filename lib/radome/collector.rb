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
      response = connection.request(:method => 'POST', :body => @data_store.keys.to_json)
      data = JSON.parse(response.body)

      # update local data from peer and push requested data back out
      connection.request(:method => 'PUT', :body => @data_store.pushpull(data).to_json)
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
      @data_store.update({'metrics' => { Socket.gethostname => { Time.now.to_i.to_s => new_data } }})
    end

  end
end
