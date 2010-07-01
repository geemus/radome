require 'sinatra/base'
require 'radome/data_store'

module Radome
  class Server < Sinatra::Base

    def initialize(*args)
      @metrics = DataStore.new(:metrics)
      super
    end

    before { content_type "application/json" }

    get '/' do
      @metrics.to_json
    end

    put '/' do
      data = JSON.parse(request.body.read)
      @metrics.update(data)
      status(200)
    end

    post '/' do
      remote_keys = JSON.parse(request.body.read)
      data = @metrics.compare(remote_keys)
      data.to_json
    end

  end
end
