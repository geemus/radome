require 'rubygems'
require 'sinatra/base'
require 'json'

module Radome

  class Collector < Sinatra::Base

    def initialize(*args)
      Thread.main[:data] = {}
      super
    end

    before { content_type "application/json" }

    get '/' do
      Thread.main[:data].to_json
    end

    put '/' do
      data = JSON.parse(request.body.read)
      for id, value in data
        Thread.main[:data][id] ||= {}
        for timestamp, metrics in value
          Thread.main[:data][id][timestamp] ||= {}
          Thread.main[:data][id][timestamp].merge!(metrics)
        end
      end
      status(200)
    end

    post '/' do
      remote_keys = JSON.parse(request.body.read)
      local_keys = {}
      for server_id, datum in Thread.main[:data]
        local_keys[server_id] = datum.keys
        remote_keys[server_id] && remote_keys[server_id] -= datum.keys
      end
      for server_id, keys in remote_keys
        local_keys[server_id] && local_keys[server_id] -= remote_keys[server_id]
      end
      data = {}
      for server_id, keys in local_keys
        data[server_id] = Thread.main[:data][server_id].reject {|key,value| !keys.include?(key)}
      end
      {'push' => data, 'pull' => remote_keys}.to_json
    end

  end

end
