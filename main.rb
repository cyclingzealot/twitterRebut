#!/usr/bin/ruby -w

puts "Lookingb in:"
puts $:
puts

require 'rubygems'
#require '/var/lib/gems/1.9.1/gems/twitter-5.16.0/lib/twitter.rb'
require 'twitter'
#require 'byebug'

str = __dir__ + '/clientConf.rb'

require str


client = Twitter::REST::Client.new($clientConf)

puts "Client ready" if client

sr = client.search("http://www.conservative.ca/cpc/protect-your-vote/")

puts sr.count

f = sr.first
puts f
puts f.methods.sort.join(', ')
puts f.id
puts f.url
