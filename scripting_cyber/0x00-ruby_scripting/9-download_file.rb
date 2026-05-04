#!/usr/bin/env ruby

require 'open-uri'
require 'uri'
require 'fileutils'

def download_file(url, local_file_path)
  URI.parse(url)

  directory = File.dirname(local_file_path)
  FileUtils.mkdir_p(directory) unless directory == '.'

  puts "Downloading file from #{url}..."

  URI.open(url) do |remote_file|
    File.open(local_file_path, 'wb') do |local_file|
      IO.copy_stream(remote_file, local_file)
    end
  end

  puts "File downloaded and saved to #{local_file_path}."
end

if ARGV.length != 2
  puts 'Usage: 9-download_file.rb URL LOCAL_FILE_PATH'
else
  download_file(ARGV[0], ARGV[1])
end