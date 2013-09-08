#!/usr/bin/env ruby
require 'yaml'
require 'twitter'
require 'tweetstream'

$NO_AT_MESSAGE = "Sorry, I won't broadcast anything with an @ in it as a spam safeguard"

@config = YAML.load(File.open('config.yaml'))

Twitter.configure do |twconfig|
    twconfig.consumer_key = @config['consumer_key']
    twconfig.consumer_secret = @config['consumer_secret']
    twconfig.oauth_token = @config['access_token']
    twconfig.oauth_token_secret = @config['access_token_secret']
end

TweetStream.configure do |twconfig|
    twconfig.consumer_key = @config['consumer_key']
    twconfig.consumer_secret = @config['consumer_secret']
    twconfig.oauth_token = @config['access_token']
    twconfig.oauth_token_secret = @config['access_token_secret']
    twconfig.auth_method = :oauth
end

begin
    @readtweets = YAML.load(File.open('seen.yaml'))
rescue Errno::ENOENT
    @readtweets = []
end

@followers = Twitter.followers({:skip_status => true}).all
@friends = Twitter.friends.all

@validUsers = []

@friends.each do |user|
    if @followers.include? user
        @validUsers << user
    else
        puts "#{user.screen_name} doesn't mutually follow, ignoring"
    end
end

def handle_dm ( dm )
    if @readtweets.include? dm.id
        puts "Duplicate DM from #{dm.sender.screen_name}, ID #{dm.id}"
    else
        if @validUsers.include? dm.sender
            puts "New DM from #{dm.sender.screen_name}, ID #{dm.id}"

            if dm.text.include? '@'
                Twitter.direct_message_create(dm.sender, $NO_AT_MESSAGE)
            else
                Twitter.update(dm.text)
            end
        else
            puts "#{dm.sender.screen_name} sent a DM, won't rebroadcast"
        end

        @readtweets << dm.id

        # yup, write it out every time.  Whatever, it's low volume
        File.open(Dir.pwd + '/seen.yaml', 'w+') {|f| f.write(@readtweets.to_yaml) }
    end
end

def handle_follow ( event )
    newFollower = Twitter.user(event[:source][:id])

    if @friends.include? newFollower
        puts "#{newFollower.screen_name} is now a mutual follower!"
        @validUsers << newFollower
    end
end

## We can ask Twitter for only DMs after a certain DM.  This will save a
## little thinking about old DMs.
mostRecentDM = @readtweets[-1]

Twitter.direct_messages({:since_id => mostRecentDM}).each do |dm|
    handle_dm (dm)
end

@client = TweetStream::Client.new

@client.on_direct_message do |dm|
    handle_dm dm
end

@client.on_anything do |event|
    if event[:event] == "follow"
        handle_follow event
    end
end

@client.userstream
