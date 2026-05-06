#!/usr/bin/env ruby

require "uri"
require "net/http"
require "json"

def get_request(url)
    uri = URI(url)
    res = Net::HTTP.get_response(uri)
    puts "Response status: #{res.code} #{res.message}"
    puts "Response body:"

    data = JSON.parse(res.body)
    puts JSON.pretty_generate(data)
end
