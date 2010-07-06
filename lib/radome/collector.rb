require 'socket'

require 'radome/data_store'

module Radome
  class Collector

    attr_accessor :data_store

    def initialize
      @data_store = DataStore.new
      sense([:recurring, :startup])
    end

    def gossip(sensors=:recurring)
      sense(sensors)
      @data_store.gossip
    end

    def hostname
      Socket.gethostname
    end

    def sense(sensors=:recurring)
      new_data = {}
      for sensor in [*sensors]
        new_data.merge!(JSON.parse(`#{File.dirname(__FILE__)}/sensors/#{sensor}.rb`))
      end
      @data_store.update({'metrics' => { hostname => { Time.now.to_i.to_s => new_data } }})
    end

  end
end
