require 'dotenv/load'
require 'json'
require 'faraday'

base_url = "https://api.airtable.com/v0"
base_id = ENV['BASE_ID']
table_id = ENV['TABLE_NAME']
personal_access_token = ENV['PERSONAL_ACCESS_TOKEN']


def fetch_airtable_urls(base_url, base_id, table_id, personal_access_token)
  conn = Faraday.new(url: "#{base_url}/#{base_id}/#{table_id}") do |faraday|
    faraday.headers['Authorization'] = "Bearer #{personal_access_token}"
    faraday.headers['Content-Type'] = 'application/json'
    faraday.adapter Faraday.default_adapter
  end
  
  begin
    response = conn.get
    if response.status == 200 
      data = JSON.parse(response.body) 
      return data["records"]
    else
      puts "Error: #{response.status} - #{response.body}"
    end
  rescue Faraday::Error => e
    puts "Error: #{e.message}"
  end
end

records = fetch_airtable_urls(base_url, base_id, table_id, personal_access_token)
urls = records&.map { |record| record["fields"]["URL"] } 
urls_length = urls.length
installations_counts = []
error_count = 0

if urls_length >= 1
  require 'nokogiri'
  require 'open-uri'
  urls.each do |url|
    begin
      doc = Nokogiri::HTML(URI.open(url))
      count = doc.xpath("//link[@rel='stylesheet'][contains(@href,'decidim_awesome')]").count

      installations_counts << count

      # puts "URL: #{url}"
      # puts "Number of matching <link> elements: #{count}"

    rescue StandardError => e
      error_count += 1
      puts "Error for URL #{url}: #{e.message}"
    end
  end
end


total_installations_counts = installations_counts.reduce { |sum, count|  sum + count}
percentage_of_installations = ((Float(total_installations_counts) / urls_length) * 100).round(2)
puts "installations_counts: #{total_installations_counts}"
puts "urls_length: #{urls_length}"
puts "Total number of errors: #{error_count}"
puts "The percentage of decidim awesome installations is: #{percentage_of_installations} %"