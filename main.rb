#!/usr/bin/env ruby

require 'telegram/bot'
require 'yaml'
require 'json'
require 'oauth2'
require "pp"
require 'unicode_plot'
require 'chronic'

# Load credentials
begin
	bot_config = YAML.load_file("secret.credentials.yml")
	bot_token  = bot_config["bot_telegram"]["bot_token"]
rescue
	puts "Wrong secret.credentials.yml file, are you sure it exist and is formated ok?"
	exit
end


# api config
config = YAML.load_file("secret.credentials.yml")
client_id = config["api"]["client_id"]
client_secret = config["api"]["client_secret"]

client = OAuth2::Client.new(client_id, client_secret, site: "https://api.intra.42.fr")

#info command
def info_command(client, message, bot)
  begin
    user = message.text.split[1]
	pp "Showing #{user}'s info"
	token = client.client_credentials.get_token
	answer = token.get("/v2/users/#{user}").parsed
	coalition = token.get("/v2/users/#{user}/coalitions").parsed[0]

  #  string_plot = token.get("v2/users/#{user}/locations_stats").parsed
  #  data = {}
  #  string_plot.each do |date, hours|
  #    t = Time.parse(hours)
  #    hours = t.hour + t.min/60 
  #    data.store(date, hours)
  #  end
  #  UnicodePlot.barplot(data: data, title: "hours").render

    if coalition == nil
		coa_name = "No coalition"
	else
		coa_name = coalition['name']
	end

	if (answer['cursus_users'].last['blackholed_at'] == nil)
		blk_str = "No Blackhole"
	else
      str_date = answer['cursus_users'].last['blackholed_at']
      date = DateTime.parse(str_date)
	  blk_str = "#{(date - DateTime.now).to_i} days, "
      blk_str << date.strftime("at %d/%m/%y")
    end
				
    bot.api.send_message(chat_id: message.chat.id, text:
                         "Full Name: #{answer['usual_full_name']}\n"\
                         "Coalition: #{coa_name}\n"\
                         "Piscine: #{answer['pool_month'].capitalize} #{answer['pool_year']}\n"\
                         "Evaluation points #{answer['correction_point'].to_s}\n"\
                         "Blackholed in #{blk_str}\n"\
                         "${string_plot}")
    bot.api.send_photo(chat_id: message.chat.id, photo: answer['image_url'])
	rescue
		bot.api.send_message(chat_id: message.chat.id, text: "Something went wrong")
	end
end

# Telegram bot config

Telegram::Bot::Client.run(bot_token) do |bot|
  bot.listen do |message|
	  if message.text.include? '/start'
		  bot.api.send_message(chat_id: message.chat.id, text: "Hello there, #{message.from.first_name}")
	  elsif message.text.include? '/info'
        info_command(client, message, bot)
	  elsif message.text.include? '/stop'
		bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
	  else
		  bot.api.send_message(chat_id: message.chat.id, text: "command not recogniced")
	  end
  end
end
