#!/usr/bin/env ruby

require 'digest'

def crack_password(hashed_password, dictionary_file)
  File.foreach(dictionary_file) do |line|
    password = line.chomp
    hashed_word = Digest::SHA256.hexdigest(password)

    if hashed_word == hashed_password
      puts "Password found: #{password}"
      return
    end
  end

  puts 'Password not found in dictionary.'
end

if ARGV.length != 2
  puts 'Usage: 10-password_cracked.rb HASHED_PASSWORD DICTIONARY_FILE'
else
  crack_password(ARGV[0], ARGV[1])
end