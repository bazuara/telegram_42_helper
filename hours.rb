#hours command
def hours_command(client, message, bot)
  begin
    user = message.text.split[1]
    if message.text.split[2] == nil
      length = 7
    else
      length = message.text.split[2].to_f
    end
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

    #render graphic
    p "Rendering..."
    g = Gruff::Line.new
    # graphic theme
    g.theme = {
      colors: [
      '#17adad'  # intra green
    ],
    marker_color: 'white',
    font_color: 'white',
    background_colors: %w[#17191f #1f212b]
    }
    
    g.title = "#{user.capitalize}\'s hours"
    hour_array = hour_array.slice(0, length)
    g.data("#{user.capitalize}", hour_array)
    g.minimum_value = 0

    g.labels = dates_hash
    g.baseline_value = hour_array.reduce(:+) / hour_array.size.to_f
    g.baseline_color = '#e7ba16'

    g.write('./temp_graph.png')
    bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('temp_graph.png', 'image/png'))
    #File.delete('temp_graph.png')
  rescue StandardError => err
    p "Rescued @hours #{err.inspect}"
    bot.api.send_message(chat_id: message.chat.id, text: "Something went wrong. *Usage:* /hours _USERNAME_ days", parse_mode: "Markdown")
  end
end
