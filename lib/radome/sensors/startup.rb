#!/usr/bin/env ruby
require 'rubygems'
require 'json'

uname = `uname -a`
os_name, hostname, os_release, os_version, architecture = uname.match(/^(\S*) (\S*) (\S*) (.*) (.*)$/).captures

boottime = `sysctl kern.boottime`
seconds, microseconds = boottime.match(/\{ sec = ([0-9]*), usec = ([0-9]*) \}/).captures
system_boot_time = Time.at(seconds.to_i, microseconds.to_i).to_i

system_time = `date +"%s"`.to_i

data = {
  :architecture     => architecture,
  :os => {
    :name     => os_name,
    :release  => os_release,
    :version  => os_version
  },
  :system_boot_time => system_boot_time,
  :system_time      => system_time
}

print data.to_json