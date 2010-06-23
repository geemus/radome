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
      content_type :json
      Thread.main[:data].to_json
    end

    put "/" do
      data = JSON.parse(request.body.read)
      Thread.main[:data].merge!(data)
      Thread.main[:data].to_json
    end

  end


end
