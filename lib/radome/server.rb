require 'sinatra/base'
require 'radome/data_store'

module Radome
  class Server < Sinatra::Base

    def initialize(*args)
      @data_store = DataStore.new({:metrics => {:expiration => 600}})
      super
    end

    before { content_type "application/json" }

    get '/' do
      @data_store.to_json(:metrics)
    end

    put '/' do
      data = JSON.parse(request.body.read)
      @data_store.update(:metrics, data['metrics'])
      status(200)
    end

    post '/' do
      data = JSON.parse(request.body.read)
      { 'metrics' => @data_store.compare(:metrics, data['metrics']) }.to_json
    end

  end
end
