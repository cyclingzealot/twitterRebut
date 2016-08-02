#!/usr/bin/ruby -w

puts "Lookingb in:"
puts $:
puts

require 'rubygems'
#require '/var/lib/gems/1.9.1/gems/twitter-5.16.0/lib/twitter.rb'
require 'twitter'
#require 'byebug'

appDir = File.expand_path("~") + '/.twitterRebutAssist/'

str = appDir + '/clientConf.rb'
if ! File.exists?(str)
    $stderr.puts "Need a file at #{str}"
end
require str


client = Twitter::REST::Client.new($clientConf)

if client
   puts "Client ready"
else
    $stderr.puts "Client error"
    exit 1
end


sr = client.search("http://www.conservative.ca/cpc/protect-your-vote/")

puts sr.count.to_s + " tweets found"

"""
f = sr.first
puts f
puts f.methods.sort.join(', ')
puts f.id
puts f.url
puts f.text
"""

sr = sr.sort_by {|t|
    t.user.followers_count
}


### Now let's read the communication history file


commHistoryPath = appDir + '/commHistory.txt'

alreadyReplied = []

if File.file?(commHistoryPath)
    File.foreach(commHistoryPath) { |l|
        ### Don't reply again to tweets already replied to
        alreadyReplied.push(l.strip.to_i)
    }
end

c = File.open(commHistoryPath, 'a');

sr.each { |t|
    puts '=' * 72
    if alreadyReplied.include?(t.id.to_i)
        $stderr.puts "Already replied to #{t.text}"
        $stderr.puts "#{t.url}"
        next
    end

    puts t.url
    puts t.text
    puts "#{t.user.followers_count} followers, from #{t.user.location}"

    puts
    print "Did you reply to this tweet? y/n/q "
    yn = $stdin.gets.chomp

    #byebug
    if yn == 'y'
        str = "#{t.id}"
        $stderr.puts "Adding #{str} to #{commHistoryPath}"
        c.puts str
    elsif yn == 'q'
        $stderr.puts "Quitting"
        break
    end


}

puts sr.first.methods.sort.join("\t")

c.close
