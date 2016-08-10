#!/usr/bin/ruby -w

puts "Lookingb in:"
puts $:
puts

require 'rubygems'
#require '/var/lib/gems/1.9.1/gems/twitter-5.16.0/lib/twitter.rb'
require 'twitter'
require 'byebug'

@appDir = File.expand_path("~") + '/.twitterRebutAssist/'

def determineMessage(screenName)
    messages = Array.new
    messages.push("Proportionality would increase number of effective votes for all Canadians, including CPC votes #fairvote #voterequality")
    messages.push("Proportionality would increase number of effective votes for all Canadians, including CPC votes #voterequality")
    messages.push("Proportionality would increase number of effective votes for all Canadians, including CPC votes #fairvote")
    messages.push("Proportionality would increase number of effective votes, including CPC votes #fairvote #voterequality")
    messages.push("Proportionality would increase number of effective votes, including CPC votes #voterequality")
    messages.push("Proportionality would increase number of effective votes, including CPC votes #fairvote")
    messages.push("Proportionality would increase nb of effective votes for all Canadians, including CPC votes #voterequality #fairvote")
    messages.push("Proportionality would increase nb of effective votes for all Canadians, including CPC votes #voterequality")
    messages.push("Proportionality would increase nb of effective votes for all Canadians, including CPC votes #fairvote")
    messages.push("Proportionality would increase nb of effective votes, including CPC votes #fairvote #voterequality")
    messages.push("Proportionality would increase nb of effective votes, including CPC votes #voterequality")
    messages.push("Proportionality would increase nb of effective votes, including CPC votes #fairvote")

    finalMessage = ''
    messages.each { |s|
        tryMessage = "@#{screenName} #{s}"

        if tryMessage.length <= 115
            finalMessage = tryMessage
            break
        end
    }

    return finalMessage
end



str = @appDir + '/clientConf.rb'
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


puts "Getting search results..."
sr = client.search("conservative.ca/cpc/protect-your-vote", {:count=>100}).to_set

sr2 =  client.search("demandareferendum.ca", {:count=>100}).to_set

sr3 = client.search("#DemandAReferendum", {:count=>100}).to_set

sr.merge(sr2)
sr.merge(sr3)

puts sr.count.to_s + " tweets found"

puts "Sorting tweets..."
sr = sr.sort {|a,b|
    locationGradeDefaultValue = 100
    locationGradeA = locationGradeDefaultValue
    locationGradeB = locationGradeDefaultValue

    locationGrades = {
        "Toronto"   => 1,
        "Halifax"   => 2,
        "Ontario"   => 4,
        "ON"   => 4,
        "Ottawa"   => 3,
        "New Brunswick"   => 2,
        "Nova Scotia"   => 2,
        "Quebec"   => 5,
        "Montreal"   => 5,
        "Montréal"   => 5,
        "QC"   => 5,
    }

    locationGrades.each{ |l,g|
        if a.user.location.include?(l) && locationGradeA == locationGradeDefaultValue
            locationGradeA = g
        end
        if b.user.location.include?(l) && locationGradeB == locationGradeDefaultValue
            locationGradeB = g
        end
    }

    if locationGradeA == locationGradeB
        a.user.followers_count - b.user.followers_count
    else
        locationGradeA - locationGradeB
    end
}


### Now let's read the communication history file



#debugger


def readHistoryFile(commHistoryPath)
	alreadyReplied = []

	puts "Opening already replied to tweets...."
	if File.file?(commHistoryPath)
	    File.foreach(commHistoryPath) { |l|
	        ### Don't reply again to tweets already replied to
	        alreadyReplied.push(l.strip.to_i)
	    }
	end

    return alreadyReplied
end


def writeFile(sr, alreadyReplied)
	listPath = '/tmp/listOfTweets.tsv'
	printf "Writting to file  #{listPath} ...."
	list = File.open(listPath, 'w');
	list.printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\n", 'Tweet Id', 'Username', 'Url', "Your message", 'Followers', 'Location', 'Text')
	sr.each { |t|
	    if ! t.geo.nil?
	        puts "FYI, Non-null tweet geo: #{t.geo} #{t.url}"
	    end

	    if alreadyReplied.include?(t.id.to_i) or t.user.location.include?("Alberta") or t.user.followers_count > 300 or t.user.screen_name.include?("CPC") or t.user.screen_name.include?("EDA")
	        next
	    end
	    list.printf("%s\t@%s\t%s\t%s\t%s\t%s\t%s\n", t.id, t.user.screen_name, t.url, determineMessage(t.user.screen_name), t.user.followers_count, t.user.location, t.text)


	}
	list.close
	printf "... Done."


	puts
	puts "Sample file"
	puts
	puts `head #{listPath}`
	puts
    puts "See #{listPath}"
    puts
end


commHistoryPath = @appDir + '/commHistory.txt'
alreadyReplied = readHistoryFile(commHistoryPath)
c = File.open(commHistoryPath, 'a');

sr.each { |t|
    puts '=' * 72
    puts
    if alreadyReplied.include?(t.id.to_i)
        $stderr.puts "Already replied to #{t.text}"
        $stderr.puts "#{t.url}"
        next
    end

    puts t.url
    puts t.text
    puts "#{t.user.followers_count} followers, @#{t.user.screen_name} from #{t.user.location} (#{t.geo}), #{t.user.url}"
    puts

    finalMessage = determineMessage(t.user.screen_name)
    puts finalMessage if ! finalMessage.empty?

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

puts

puts sr.first.user.methods.sort.join("\t")

c.close


alreadyReplied = readHistoryFile(commHistoryPath)
writeFile(sr, alreadyReplied)


