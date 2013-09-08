require 'yaml'
require 'twitter'
require 'tweetstream'

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

followers = Twitter.followers
friends = Twitter.friends
@config['validusers'].each do |user| 
    twuser = Twitter.user(user)
    puts "#{user} doesn't follow me!" unless followers.include? twuser
    puts "I need to follow #{user}!" unless friends.include? twuser
end

def handle_dm ( dm )
    if @readtweets.include? dm.id
        # we've already seen this one, don't do anything with it
    else
        if @config['validusers'].include? dm.sender.screen_name
            puts "New DM from #{dm.sender.screen_name}, ID #{dm.id}"
            Twitter.update(dm.text)
        else
            puts "#{dm.sender.screen_name} sent a DM, won't rebroadcast"
        end

        @readtweets << dm.id

        # yup, write it out every time.  Whatever, it's low volume
        File.open(Dir.pwd + '/seen.yaml', 'w+') {|f| f.write(@readtweets.to_yaml) }
    end
end

Twitter.direct_messages.each do |dm|
    handle_dm (dm)
end

@client = TweetStream::Client.new

@client.on_direct_message do |dm|
    handle_dm dm
end

@client.userstream
