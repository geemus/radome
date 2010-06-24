require 'sinatra/base'
require 'json'

module Radome

  class Collector < Sinatra::Base

    def initialize(*args)
      Thread.main[:data] = {}
      super
    end

    before { content_type "application/json" }

    get "/" do
      Thread.main[:data].to_json
    end

    put "/" do
      data = JSON.parse(request.body.read)
      for key, value in data
        Thread.main[:data][key] ||= {}
        for sub_key, sub_value in value
          Thread.main[:data][key][sub_key] ||= {}
          Thread.main[:data][key][sub_key].merge!(sub_value)
        end
      end
      Thread.main[:data].to_json
    end

  end

end
