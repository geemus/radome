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

    def compare(remote_data)
      expire
      comparison = {}
      for type, remote_keys in remote_data
        comparison[type] = { 'push' => {}, 'pull' => remote_keys }
        local_keys = {}
        for server_id, data in Thread.main[type]
          local_keys[server_id] = data.keys
          comparison[type]['pull'][server_id] && comparison[type]['pull'][server_id] -= data.keys
        end
        for server_id, keys in comparison[type]['pull']
          local_keys[server_id] && local_keys[server_id] -= comparison[type]['pull'][server_id]
        end
        for server_id, keys in local_keys
          comparison[type]['push'][server_id] = Thread.main[type][server_id].reject {|key,value| !keys.include?(key)}
        end
      end
      comparison
    end

    def data
      data = {}
      for type, options in @stores
        data[type] = Thread.main[type]
      end
      data
    end

    def expire
      for type, options in @stores
        case options[:expiration]
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
    end

    def keys
      expire
      keys = {}
      for type, options in @stores
        keys[type] = {}
        for key, value in Thread.main[type]
          keys[type][key] = value.keys
        end
      end
      keys
    end

    def to_json
      data.to_json
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
      end
      expire
    end

  end

end
