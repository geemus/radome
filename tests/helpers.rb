require File.join(File.dirname(__FILE__), '..', 'lib', 'radome')
require 'excon'

def with_server(&block)
  pid = Process.fork do
    Radome::Server.run
  end
  yield
  Process.kill(9, pid)
end

def connection
  @connection ||= Excon.new('http://localhost:9292/')
end

def get_data
  data = connection.request(:method => 'GET').body
  JSON.parse(data)
end

with_server do
  sleep(5)
  require 'pp'
  p 'remote'
  pp get_data
end
