require 'json'
require 'faraday'

base_url = "https://api.airtable.com/v0"
base_id = ENV['BASE_ID']
table_id = ENV['TABLE_NAME']
personal_access_token = ENV['API_KEY']
endpoint = "#{base_url}/#{base_id}/#{table_id}"


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

# Print the extracted URLs
if urls
  urls.each do |url|
    puts "URL: #{url}"
  end
end
