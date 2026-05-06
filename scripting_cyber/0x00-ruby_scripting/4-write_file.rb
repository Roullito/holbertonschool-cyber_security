#!/usr/bin/env ruby

require "json"

def merge_json_files(file1_path, file2_path)
    file1_content = File.read(file1_path)
    file2_content = File.read(file2_path)

    arr1 = JSON.parse(file1_content)
    arr2 = JSON.parse(file2_content)

    merged = arr2 + arr1

    File.write(file2_path, JSON.pretty_generate(merged))

    puts "Merged JSON written to #{file2_path}"
end
