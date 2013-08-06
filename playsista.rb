require 'twitter'
require 'open-uri'

Twitter.configure do |config|
  config.consumer_key = ENV["CONSUMER_KEY"]
  config.consumer_secret = ENV["CONSUMER_SECRET"]
  config.oauth_token = ENV["OAUTH_TOKEN"]
  config.oauth_token_secret = ENV["OAUTH_TOKEN_SECRET"]
end

Trans = { 'January' => 'Janvier',
          'February' => 'Fevrier',
          'March' => 'Mars',
          'April' => 'Avril',
          'May' => 'Mai',
          'June' => 'Juin',
          'July' => 'Juillet',
          'August' => 'Aout',
          'September' => 'Septembre',
          'October' => 'Octobre',
          'November' => 'Novembre',
          'December' => 'Decembre'}

def save_last_rt(last_rt_id)
  begin
    open("last_rt_id.txt", "w") do |f|
      f.puts last_rt_id
    end
  rescue => e
    puts "file save error"
  end
end

def load_last_rt
  begin
    open("last_rt_id.txt", "r") do |f|
      data = f.readlines
      data[0].to_i
    end
  rescue => e
    puts "file load error"
  end
end

def is_spotify_pl_url(url)
  url =~ /http:\/\/open\.spotify\.com\/user\/.+\/playlist\/.+/
end

def search(month, last_id)
  new_last_id = nil

  Twitter.search("spotify playlist #{month} OR #{Trans[month]}", :rpp => 100, :result_type => "recent", :include_entities => true).results.map do |s|
    break if s.id == last_id
    has_valid_pl_url = false

    unless s.text =~ /.*RT.*/ or s.urls.empty?
      s.urls.each do |url|
        begin
          open(url.expanded_url) do |final_url|
            s_url = final_url.base_uri.to_s
            has_valid_pl_url = true if is_spotify_pl_url s_url
            puts s_url if has_valid_pl_url
          end
        rescue
          puts "failed"
        end
      end

      if has_valid_pl_url
        Twitter.retweet(s.id)
      end

      new_last_id ||= s.id

    end
  end
  new_last_id
end

if $0 == __FILE__
  last_id = load_last_rt
  current_month = Time.now.localtime.strftime("%B")
  puts " * Current month is " + current_month
  puts " * Last retweet was #{last_id}"
  new_last_id = search(current_month, last_id)
  last_id = new_last_id if new_last_id
  puts " * Last retweet is now #{last_id}"
  save_last_rt(last_id)
end