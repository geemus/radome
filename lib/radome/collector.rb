require 'rubygems'
require 'sinatra/base'

require 'radome/data_store'

module Radome

  class Collector < Sinatra::Base

    def initialize(*args)
      @store = DataStore.new
      super
    end

    before { content_type "application/json" }

    get '/' do
      @store.to_json
    end

    put '/' do
      data = JSON.parse(request.body.read)
      @store.update(data)
      status(200)
    end

    post '/' do
      remote_keys = JSON.parse(request.body.read)
      data = @store.compare(remote_keys)
      data.to_json
    end

  end

end
