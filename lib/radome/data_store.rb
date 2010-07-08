require 'rubygems'
require 'json'

module Radome
  class DataStore

    def initialize
      srand
      @stores = {
        'config'   => {},
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
      comparison.to_json
    end

    def data
      data = {}
      for type, options in @stores
        data[type] = Thread.main[type]
      end
      data.to_json
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

    def gossip
      if Thread.main['config']['peers'] &&
          (peers = Thread.main['config']['peers'].values.first) &&
          (peer = peers[rand(peers.length)])
        connection = Excon.new(peer)

        # find available local keys and sync this list with peer
        response = connection.request(:method => 'POST', :body => keys)
        data = JSON.parse(response.body)

        # update local data from peer and push requested data back out
        push = {}
        for type, datum in data
          push[type] = datum['push']
        end
        update(push)

        pull = {}
        for type, datum in data
          pull[type] = {}
          for server_id, keys in datum['pull']
            pull[type][server_id] = Thread.main[type][server_id].reject {|key,value| !keys.include?(key)}
          end
        end

        connection.request(:method => 'PUT', :body => pull.to_json)
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
      keys.to_json
    end

    def update(new_data)
      for type, data in new_data
        for id, value in data
          Thread.main[type][id] ||= {}
          for timestamp, data in value
            case data
            when Array
              Thread.main[type][id][timestamp] ||= []
              Thread.main[type][id][timestamp] |= data
            when Hash
              Thread.main[type][id][timestamp] ||= {}
              Thread.main[type][id][timestamp].merge!(data)
            end
          end
        end
      end
      expire
    end

  end

end
