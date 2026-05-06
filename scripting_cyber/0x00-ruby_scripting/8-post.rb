#!/usr/bin/env ruby

require "uri"
require "net/http"
require "json"

def post_request(url, body_params)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    req = Net::HTTP::Post.new(uri.request_uri)
    req["Content-Type"] = "application/json"
    req.body = body_params.to_json

    res = http.request(req)

    puts "Response status: #{res.code} #{res.message}"
    puts "Response body:"

    begin
        data = JSON.parse(res.body)
        puts JSON.pretty_generate(data)
    rescue JSON::ParseError
        puts response.body
    end
end
