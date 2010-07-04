require 'rubygems'
require 'json'

module Radome
  class DataStore

    def initialize
      @stores = {
        'metrics'  => { :expiration => 60 * 10 }
      }
      for key, values in @stores
        Thread.main[key] ||= {}
      end
    end

    def compare(type, remote_keys)
      expire(type)
      local_keys = {}
      for server_id, data in Thread.main[type]
        local_keys[server_id] = data.keys
        remote_keys[server_id] && remote_keys[server_id] -= data.keys
      end
      for server_id, keys in remote_keys
        local_keys[server_id] && local_keys[server_id] -= remote_keys[server_id]
      end
      data = {}
      for server_id, keys in local_keys
        data[server_id] = Thread.main[type][server_id].reject {|key,value| !keys.include?(key)}
      end
      {'push' => data, 'pull' => remote_keys}
    end

    def data(type)
      Thread.main[type]
    end

    def expire(type)
      case @stores[type][:expiration]
      when Integer
        expiration = (Time.now - 60 * 10).to_i
        for server_id, data in Thread.main[type]
          data.reject! {|key, value| key.to_i <= expiration }
        end
      when :maximum
        for server_id, data in Thread.main[type]
          maximum = data.keys.max
          data.reject! {|key, value| key != maximum}
        end
      end
      Thread.main[type].reject! {|server_id, data| data.empty?}
    end

    def keys
      keys = {}
      for type, options in @stores
        expire(type)
        keys[type] = {}
        for key, value in Thread.main[type]
          keys[type][key] = value.keys
        end
      end
      keys
    end

    def to_json(type)
      Thread.main[type].to_json
    end

    def update(new_data)
      for type, data in new_data
        for id, value in data
          Thread.main[type][id] ||= {}
          for timestamp, metrics in value
            Thread.main[type][id][timestamp] ||= {}
            Thread.main[type][id][timestamp].merge!(metrics)
          end
        end
        if @stores[type][:expiration] == :maximum
          expire(type)
        end
      end
    end

  end

end
