require 'socket'

require 'radome/data_store'

module Radome
  class Collector

    attr_accessor :data_store

    def initialize
      @data_store = DataStore.new
      sense([:boot_time, :load, :uname])
    end

    def gossip(sensors=[:load])
      sense(sensors)
      @data_store.gossip
    end

    def hostname
      Socket.gethostname
    end

    def sense(sensors=[:load])
      new_data = {}
      for sensor in [*sensors]
        new_data.merge!(send(sensor))
      end
      @data_store.update({'metrics' => { hostname => { Time.now.to_i.to_s => new_data } }})
    end

    private

    def boot_time
      boottime = `sysctl kern.boottime`
      seconds, microseconds = boottime.match(/\{ sec = ([0-9]*), usec = ([0-9]*) \}/).captures
      {:system_boot_time => Time.at(seconds.to_i, microseconds.to_i).to_i}
    end

    def load
      uptime = `uptime`
      one_minute_load, five_minute_load, fifteen_minute_load = uptime.match(/load averages: ([\.0-9]*) ([\.0-9]*) ([\.0-9]*)/).captures
      {
        :load => {
          :one_minute     => one_minute_load.to_f,
          :five_minute    => five_minute_load.to_f,
          :fifteen_minute => fifteen_minute_load.to_f
        }
      }
    end

    def uname
      uname = `uname -a`
      os_name, hostname, os_release, os_version, architecture = uname.match(/^(\S*) (\S*) (\S*) (.*) (.*)$/).captures
      {
        :architecture => architecture,
        :os => {
          :name     => os_name,
          :release  => os_release,
          :version  => os_version
        }
      }
    end

  end

end
