require 'twitter'
require 'open-uri'

Twitter.configure do |config|
  config.consumer_key = ENV["CONSUMER_KEY"]
  config.consumer_secret = ENV["CONSUMER_SECRET"]
  config.oauth_token = ENV["OAUTH_TOKEN"]
  config.oauth_token_secret = ENV["OAUTH_TOKEN_SECRET"]
end

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

def extract_playlists_url(text)
  URI::extract(text, "http").each do |u|
    open(u) do |h|
      yield h.base_uri
    end
  end
end

def search(month, last_id)
  new_last_id = nil
  Twitter.search("spotify playlist " + month, :rpp => 50, :result_type => "recent", :include_entities => true).results.map do |s|
    break if s.id == last_id
    unless s.text =~ /.*RT.*/ or s.urls.empty?
      puts "[#{s.id}][#{s.from_user}]:", "#{s.text}"
      s.urls.each do |url|
        open(url.expanded_url) do |final_url|
          puts "URL:" + final_url.base_uri.to_s
        end
      end
      Twitter.retweet(s.id)
      new_last_id ||= s.id
    end
  end
  new_last_id
end

if $0 == __FILE__
  last_id = load_last_rt
  current_month = Time.now.localtime.strftime("%B")
  puts " * Current month is " + current_month
  puts " * Last retweet is #{last_id}"
  new_last_id = search(current_month, last_id)
  last_id = new_last_id if new_last_id
  puts "LATEST: #{last_id}"
  save_last_rt(last_id)
end
