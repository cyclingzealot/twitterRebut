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

=begin
    messages.push("What politicians shouldn't have is 100% power with ~40% of votes. Legislature should reflect the vote #voterequality #cdnpoli #fairvote #ERRE")
    messages.push("What politicians shouldn't have is 100% power with ~40% of votes. Legislature should reflect the vote #voterequality #cdnpoli #fairvote")
    messages.push("What politicians shouldn't have is 100% power with ~40% of votes. Legislature should reflect the vote #voterequality #fairvote")
    messages.push("What politicians shouldn't have is 100% power with ~40% of votes. Legislature should reflect the vote #voterequality")
    messages.push("What politicians shouldn't have is 100% power with ~40% of votes. Legislature should reflect the vote #fairvote")
    messages.push("What politicians shouldn't have: 100% power with ~40% of vote. Legislature should reflect the vote #fairvote")
    messages.push("What politicians shouldn't have: 100% power with ~40% of vote. Legislature should reflect vote #fairvote")
    messages.push("Politicians shouldn't have 100% power with ~40% of vote. Legislature should reflect the vote #fairvote")
    messages.push("Politicians shouldn't have 100% power with ~40% of vote. Legislature should reflect vote #fairvote")
=end

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
searchTerms = ["conservative.ca/cpc/protect-your-vote", "demandareferendum.ca", "#DemandAReferendum", "ronaambrose/videos/10153984927048525/", "Liberals' electoral reform debate denies Canadians their say"]

sr = Set.new
searchTerms.each { |st|
    srSub = client.search(st, {:count=>100}).to_set
    puts "#{srSub.count} results found for search terms '#{st}...'"
    sr.merge(srSub)
}

puts sr.count.to_s + " tweets found"

puts "Sorting tweets..."
sr = sr.sort {|a,b|
    locationGradeDefaultValue = 100
    locationGradeA = locationGradeDefaultValue
    locationGradeB = locationGradeDefaultValue

    locationGrades = {
        "Toronto"   => 1,
        "Oakville"   => 2,
        "Halifax"   => 3,
        "Ontario"   => 5,
        "ON"   => 5,
        "Ottawa"   => 4,
        "New Brunswick"   => 3,
        "Nova Scotia"   => 3,
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


def readHistoryFile(commHistoryPath)
	alreadyReplied = []

	puts "Opening already replied to tweets...."
	if File.file?(commHistoryPath)
		File.foreach(commHistoryPath) { |l|
		    username = l.strip
		    if !(/^[1-9][0-9]*$/).match(l.strip).nil?
		            t = Twitter::Tweet.new({:id => l.strip.to_i})
		            username = t.user.screen_name
		    end
		    ### Don't reply again to tweets already replied to
		    if ! username.nil?
                alreadyReplied.push(username.strip)
            else
                alreadyReplied.push(l.strip.to_i)
            end
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

	    if alreadyReplied.include?(t.user.screen_name) or alreadyReplied.include?(t.id) or t.user.location.include?("Alberta") or t.user.followers_count > 300 or t.user.screen_name.include?("CPC") or t.user.screen_name.include?("EDA")
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
    if alreadyReplied.include?(t.user.screen_name) or alreadyReplied.include?(t.id)
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
        str = "#{t.user.screen_name}"
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


