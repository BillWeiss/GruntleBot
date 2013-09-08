require 'YAML'
require 'Twitter'
require 'tweetstream'

config = YAML.load(File.open('config.yaml'))

client = Twitter.configure do |twconfig|
    twconfig.consumer_key = config['consumer_key']
    twconfig.consumer_secret = config['consumer_secret']
    twconfig.oauth_token = config['access_token']
    twconfig.oauth_token_secret = config['access_token_secret']
end

begin
    readtweets = YAML.load(File.open('seen.yaml'))
rescue Errno::ENOENT
    readtweets = []
end

config['validusers'].each do |user| 
    puts "#{user} doesn't follow me!" unless Twitter.followers.include? Twitter.user(user)
    puts "I need to follow #{user}!" unless Twitter.friends.include? Twitter.user(user)
end




File.open(Dir.pwd + 'seen.yaml', 'w+') {|f| f.write(readtweets.to_yaml) }
