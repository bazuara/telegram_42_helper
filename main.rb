#!/usr/bin/env ruby

require 'telegram/bot'
require 'yaml'
require 'json'
require 'oauth2'
require "pp"
require 'unicode_plot'
require 'gruff'

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

#hours command
def hours_command(client, message, bot)
    user = message.text.split[1]
	token = client.client_credentials.get_token
    string_plot = token.get("v2/users/#{user}/locations_stats").parsed
    p "Hours fetched for #{user}, calculating..."
    
    # process data hash to split in two for gruff to render
    data = {}
    string_plot.each do |d, h|
      t = Time.parse(h)
      h = t.hour + t.min/60
      d = Date.strptime(d, '%Y-%m-%d')
      d = d.strftime('%d-%m')
      data.store(d, h)
    end
    dates_hash = {}
    hour_array = []

    data.each_with_index do |(d, h), i|
      dates_hash.store(i, d)
      hour_array.push(h)
    end

#    p "dates hash:"
#    pp dates_hash
#    p "hour array:"
#    pp hour_array
    
    #render graphic
    p "Rendering..."
    g = Gruff::Line.new
    g.title = "#{user}\'s hours"
    hour_array = hour_array.slice(0, 7)
    g.data("#{user}", hour_array)

    g.labels = dates_hash
    g.baseline_value = hour_array.reduce(:+) / hour_array.size.to_f
    g.baseline_color = 'green'

    g.write('./line_baseline.png')
    bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('line_baseline.png', 'image/png'))
end

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
		  bot.api.send_message(chat_id: message.chat.id, text: "command not recognized")
	  end
  end
end
