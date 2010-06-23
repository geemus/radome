require File.join(File.dirname(__FILE__), '..', 'radome')

collector = Thread.new { Rack::Handler::WEBrick.run(Radome::Collector.new, :Port => 9292) }
Kernel.trap('INT', lambda { collector.exit })
collector.join
