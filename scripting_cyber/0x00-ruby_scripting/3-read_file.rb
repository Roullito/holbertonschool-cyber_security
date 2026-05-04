#!/usr/bin/env ruby

require 'json'

def count_user_ids(path)
  content = File.read(path)
  data = JSON.parse(content)
  counts = Hash.new(0)

  data.each do |item|
    user_id = item['userId']
    counts[user_id] += 1
  end

  counts.keys.sort.each do |user_id|
    puts "#{user_id}: #{counts[user_id]}"
  end
end