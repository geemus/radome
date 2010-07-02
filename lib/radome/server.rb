require 'sinatra/base'
require 'radome/data_store'

module Radome
  class Server < Sinatra::Base

    def initialize(*args)
      @metrics = DataStore.new({:type => :metrics})
      super
    end

    before { content_type "application/json" }

    get '/' do
      @metrics.to_json
    end

    put '/' do
      data = JSON.parse(request.body.read)
      @metrics.update(data['metrics'])
      status(200)
    end

    post '/' do
      data = JSON.parse(request.body.read)
      { 'metrics' => @metrics.compare(data['metrics']) }.to_json
    end

  end
end
