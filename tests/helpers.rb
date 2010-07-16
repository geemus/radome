require File.join(File.dirname(__FILE__), '..', 'lib', 'radome')
require 'excon'

def with_server(&block)
  pid = Process.fork do
    Radome::Server.run
  end
  yield
  Process.kill(9, pid)
end

with_server do
  sleep(5)
  require 'pp'
  pp JSON.parse(Excon.get('http://localhost:9292/').body)
end
