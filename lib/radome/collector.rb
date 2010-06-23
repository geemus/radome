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
        Thread.main[:data][key].merge!({Time.now => value})
      end
      Thread.main[:data].to_json
    end

  end

end
