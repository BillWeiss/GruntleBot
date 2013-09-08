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

Twitter.update("Working on the bot code.  It's a good start!")
