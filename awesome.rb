require 'dotenv/load'
require 'json'
require 'faraday'
require 'nokogiri'
require 'open-uri'

base_url = "https://api.airtable.com/v0"
base_id = ENV['BASE_ID']
table_id = ENV['TABLE_NAME']
personal_access_token = ENV['PERSONAL_ACCESS_TOKEN']


def fetch_airtable_urls(base_url, base_id, table_id, personal_access_token, offset = nil)
  conn = Faraday.new(url: "#{base_url}/#{base_id}/#{table_id}") do |faraday|
    faraday.headers['Authorization'] = "Bearer #{personal_access_token}"
    faraday.headers['Content-Type'] = 'application/json'
    faraday.adapter Faraday.default_adapter
  end

  params = { offset: offset }
  
  begin
    response = conn.get do |req|
      req.params = params if offset
    end

    if response.status == 200 
      data = JSON.parse(response.body) 
      records = data["records"]
      offset = data["offset"]

      process_records(records)

      fetch_airtable_urls(base_url, base_id, table_id, personal_access_token, offset) if offset
    else
      puts "Error: #{response.status} - #{response.body}"
    end
  rescue Faraday::Error => e
    puts "Error: #{e.message}"
  end
end

def process_records(records)
  installations_counts = []
  error_count = 0

  records.each do |record|
    url = record["fields"]["URL"]
    begin
      doc = Nokogiri::HTML(URI.open(url))
      count = doc.xpath("//link[@rel='stylesheet'][contains(@href,'decidim_awesome')]").count
      installations_counts << count
    rescue StandardError => e
      error_count += 1
      puts "Error for URL #{url}: #{e.message}"
    end
  end
  urls_length = records.length
  total_installations_counts = installations_counts.reduce { |sum, count|  sum + count}
  percentage_of_installations = ((Float(total_installations_counts) / urls_length) * 100).round(2)
  puts "installations_counts: #{total_installations_counts}"
  puts "urls_length: #{urls_length}"
  puts "Total number of errors: #{error_count}"
  puts "The percentage of decidim awesome installations is: #{percentage_of_installations} %"
end


fetch_airtable_urls(base_url, base_id, table_id, personal_access_token)