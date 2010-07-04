require 'sinatra/base'
require 'radome/data_store'

module Radome
  class Server < Sinatra::Base

    def initialize(*args)
      @data_store = DataStore.new
      super
    end

    before { content_type "application/json" }

    get '/' do
      @data_store.data
    end

    put '/' do
      data = JSON.parse(request.body.read)
      @data_store.update(data)
      status(200)
    end

    post '/' do
      data = JSON.parse(request.body.read)
      @data_store.compare(data)
    end

  end
end
