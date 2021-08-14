#!/usr/bin/env ruby
# frozen_string_literal: true

require 'telegram/bot'
require 'yaml'
require 'json'
require 'oauth2'
require 'pp'
require 'unicode_plot'
require 'gruff'

load 'hours.rb'
load 'info.rb'

# Load credentials
begin
  bot_config = YAML.load_file('secret.credentials.yml')
  bot_token  = bot_config['bot_telegram']['bot_token']
rescue StandardError => e
  p "Rescue @Load_credentials #{e.inspect}"
  p 'Wrong secret.credentials.yml file, are you sure it exist and is formated ok?'
  exit
end

# api config
config = YAML.load_file('secret.credentials.yml')
client_id = config['api']['client_id']
client_secret = config['api']['client_secret']

client = OAuth2::Client.new(client_id, client_secret, site: 'https://api.intra.42.fr')

# Telegram bot config

Telegram::Bot::Client.run(bot_token) do |bot|
  bot.listen do |message|
    if message.text.include? '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hello there, #{message.from.first_name}")
    elsif message.text.include? '/info'
      info_command(client, message, bot)
    elsif message.text.include? '/hours'
      hours_command(client, message, bot)
    elsif message.text.include? '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
      exit
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'command not recognized')
    end
  end
end
