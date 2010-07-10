#!/usr/bin/env ruby
require 'rubygems'
require 'json'

uptime = `uptime`
one_minute_load, five_minute_load, fifteen_minute_load = uptime.match(/load averages: ([\.0-9]*) ([\.0-9]*) ([\.0-9]*)/).captures

data = {
  :load => {
    :one_minute     => one_minute_load.to_f,
    :five_minute    => five_minute_load.to_f,
    :fifteen_minute => fifteen_minute_load.to_f
  }
}

print data.to_json