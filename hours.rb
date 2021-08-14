# hours command
# frozen_string_literal: true

# process data hash to split in two for gruff to render
class UserData
  attr_accessor :string_plot, :dates_hash, :hour_array

  def initialize(string_plot)
    @string_plot = string_plot
    @dates_hash = {}
    @hour_array = []
    process_time(string_plot)
  end

  def process_time(string_plot)
    p 'processing time'
    daysanhours = {}
    string_plot.each do |d, h|
      daysanhours.store(Date.strptime(d, '%Y-%m-%d').strftime('%d-%m'), Time.parse(h).hour + Time.parse(h).min / 60)
    end

    daysanhours.each_with_index do |(d, h), i|
      @dates_hash.store(i, d)
      @hour_array.push(h)
    end
  end

  def median(len)
    @hour_array.slice(0, len).reduce(:+) / len
  end
end

def render_hours(user_data, len, user)
  p 'rendering'
  g = Gruff::Line.new
  # graphic theme
  g.theme = {colors: ['#17adad'], marker_color: 'white', font_color: 'white', background_colors: %w[#17191f #1f212b]}

  g.title = "#{user}\'s hours"
  g.data(user, user_data.hour_array.slice(0, len))
  g.minimum_value = 0

  g.labels = user_data.dates_hash
  g.baseline_value = user_data.median(len)
  g.baseline_color = '#e7ba16'

  g.write('./temp_graph.png')
end

def lenorseven(message)
  if message.text.split[2].nil?
    7
  else
    message.text.split[2].to_f
  end
end

def get_hours_string(user, client)
  token = client.client_credentials.get_token
  token.get("v2/users/#{user}/locations_stats").parsed
end

def send_and_delete(bot, message)
  bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('temp_graph.png', 'image/png'))
  File.delete('temp_graph.png')
end

def hours_command(client, message, bot)
  user = message.text.split[1]
  len = lenorseven(message)
  p "Hours request at #{Time.now} for user #{user}"
  string_plot = get_hours_string(user, client)
  user_data = UserData.new(string_plot)
  render_hours(user_data, len, user)
  send_and_delete(bot, message)
rescue StandardError => e
  p "Rescued @hours #{e.inspect}"
  bot.api.send_message(chat_id: message.chat.id, text: 'Something went wrong.', parse_mode: 'Markdown')
end
