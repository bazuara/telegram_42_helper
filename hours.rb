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

    #render graphic
    p "Rendering..."
    g = Gruff::Line.new
    # graphic theme
    g.theme = {
      colors: [
      '#17adad',  # intra green
      '#6886B4',  # blue
      '#72AE6E',  # green
      '#D1695E',  # red
      '#8A6EAF',  # purple
      '#EFAA43',  # orange
      'white'
    ],
    marker_color: 'white',
    font_color: 'white',
    background_colors: %w[#17191f #1f212b]
    }
    
    g.title = "#{user.capitalize}\'s hours"
    hour_array = hour_array.slice(0, 7)
    g.data("#{user.capitalize}", hour_array)
    g.minimum_value = 0

    g.labels = dates_hash
    g.baseline_value = hour_array.reduce(:+) / hour_array.size.to_f
    g.baseline_color = '#e7ba16'

    g.write('./temp_graph.png')
    bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('temp_graph.png', 'image/png'))
end
