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
      blk_str << date.strftime("*at* %d/%m/%y")
    end
				
    info_string = "*Full Name:* #{answer['usual_full_name']}\n"\
    "*Coalition:* #{coa_name}\n"\
    "*Piscine:* #{answer['pool_month'].capitalize} #{answer['pool_year']}\n"\
    "*Evaluation points:* #{answer['correction_point'].to_s}\n"\
    "*Blackholed in* #{blk_str}"

    bot.api.send_photo(chat_id: message.chat.id, photo: answer['image_url'], caption: info_string, parse_mode: "Markdown")
	rescue
		bot.api.send_message(chat_id: message.chat.id, text: "Something went wrong")
	end
end

