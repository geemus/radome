require 'rubygems'
require 'json'

module Radome
  class DataStore

    attr_reader :data

    def initialize(type)
      Thread.main[type] ||= {}
      @data = Thread.main[type]
    end

    def compare(remote_keys)
      expire
      local_keys = {}
      for server_id, data in @data
        local_keys[server_id] = data.keys
        remote_keys[server_id] && remote_keys[server_id] -= data.keys
      end
      for server_id, keys in remote_keys
        local_keys[server_id] && local_keys[server_id] -= remote_keys[server_id]
      end
      data = {}
      for server_id, keys in local_keys
        data[server_id] = @data[server_id].reject {|key,value| !keys.include?(key)}
      end
      {'push' => data, 'pull' => remote_keys}
    end

    def expire
      expiration = (Time.now - 60 * 10).to_i
      for server_id, data in @data
        data.reject! {|key, value| key.to_i <= expiration }
      end
      @data.reject! {|server_id, data| data.empty?}
    end

    def keys
      expire
      keys = {}
      for key, value in @data
        keys[key] = value.keys
      end
      keys
    end

    def to_json
      @data.to_json
    end

    def update(new_data)
      for id, value in new_data
        @data[id] ||= {}
        for timestamp, metrics in value
          @data[id][timestamp] ||= {}
          @data[id][timestamp].merge!(metrics)
        end
      end
    end

  end
end
