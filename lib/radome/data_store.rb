require 'rubygems'
require 'json'

class DataStore

  attr_reader :data

  def initialize
    Thread.current[:data] ||= {}
    @data = Thread.current[:data]
  end

  def compare(remote_keys)
    local_keys = {}
    for server_id, datum in @data
      local_keys[server_id] = datum.keys
      remote_keys[server_id] && remote_keys[server_id] -= datum.keys
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

  def keys
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
