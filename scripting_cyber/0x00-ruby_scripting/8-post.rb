#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

def post_request(url, body_params = {})
  uri = URI(url)

  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = JSON.generate(body_params)

  response = Net::HTTP.start(
    uri.hostname,
    uri.port,
    use_ssl: uri.scheme == 'https'
  ) do |http|
    http.request(request)
  end

  puts "Response status: #{response.code} #{response.message}"
  puts 'Response body:'

  begin
    puts JSON.pretty_generate(JSON.parse(response.body))
  rescue JSON::ParserError
    puts response.body
  end
end
