#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

if ARGV.size < 2
  puts "Usage: #{__FILE__} github_token path_to_file_with_github_logins"
  puts "\nYou need a personal access token for GitHub, see"
  puts "https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/"
  puts "\nExample: #{__FILE__} 123abc ../github-users.txt"
  exit
end

token = ARGV[0]
path = ARGV[1]
unless File.file?(path)
  puts "Invalid path: #{path} is not a file"
  exit
end

file = File.read(path)
logins = file.split(/\s+/)
puts "Found #{logins.size} GitHub username(s) in #{path}"

def star_count_query_for(login, query_alias)
  query = %Q(
    #{query_alias}: user(login: "#{login}") {
      starredRepositories(first: 0) { totalCount }
    }
  )
  query.strip
end

users = []
logins.each_with_index do |login, i|
  query_alias = "user#{i}"
  users << {
    login: login,
    query: star_count_query_for(login, query_alias),
    query_alias: query_alias
  }
end

def run_query(query, token)
  api_url = 'https://api.github.com/graphql'
  uri = URI.parse(api_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  headers = { 'Authorization' => "bearer #{token}" }
  body = { query: "query { #{query} }" }
  request = Net::HTTP::Post.new(uri.request_uri, headers)
  request.body = body.to_json
  response = http.request(request)

  unless response.code == '200'
    puts "#{response.code} error: #{response.body}"
    exit
  end

  json = JSON.parse(response.body)

  if errors = json['errors']
    errors.each do |error|
      puts "Error: #{error['message']}"
    end
    exit
  end

  json['data']
end

star_counts = {}
found_users = 0

batches = users.each_slice(20)
puts "Processing users in #{batches.size} batches..." if batches.size > 1
batches.each_with_index do |users_batch, i|
  puts "Processing batch #{i + 1}..."
  query = users_batch.map { |user| user[:query] }.join(' ')
  result = run_query(query, token)
  users_batch.each do |user|
    if data = result[user[:query_alias]]
      found_users += 1
      star_counts[user[:login]] = data['starredRepositories']['totalCount']
    end
  end
end

puts "Found #{found_users} GitHub user(s)"
star_counts = star_counts.sort_by { |login, count| -count }.to_h

output_path = 'gh-starstruck-results.json'
File.open(output_path, 'w') do |file|
  file.puts JSON.pretty_generate(star_counts)
end

puts "Wrote results to #{output_path}"
