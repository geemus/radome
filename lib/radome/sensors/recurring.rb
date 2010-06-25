#!/usr/bin/env ruby
require 'rubygems'
require 'json'

hostname = `hostname`.chomp!

uptime = `uptime`
one_minute_load, five_minute_load, fifteen_minute_load = uptime.match(/load averages: ([\.0-9]*) ([\.0-9]*) ([\.0-9]*)/).captures

system_time = `date +"%s"`.to_i

data = {
  :load => {
    :one_minute     => one_minute_load.to_f,
    :five_minute    => five_minute_load.to_f,
    :fifteen_minute => fifteen_minute_load.to_f
  },
  :system_time => system_time
}

print data.to_json