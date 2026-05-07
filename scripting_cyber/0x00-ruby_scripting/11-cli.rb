#!/usr/bin/env ruby

require "optparse"

parser = OptionParser.new
parser.banner = "Usage: cli.rb [options]"

parser.on('-a', '--add TASK', 'Add a new task') do |value|
    File.open("tasks.txt", "a") { |f| f.puts value }
    puts "Task '#{value}' added."
end

parser.on('-l', '--list', 'List all tasks') do
    if File.exist?("tasks.txt")
        File.readlines("tasks.txt").each_with_index do |task, index|
            puts "#{index + 1}. #{task.strip}"
        end
    else
        puts "No tasks found."
    end
end

parser.on('-r', '--remove INDEX', 'Remove a task by index') do |value|
    if File.exist?("tasks.txt")
        tasks = File.readlines("tasks.txt")
        index = value.to_i - 1

        if index >= 0 && index < tasks.length
            removed_task = tasks.delete_at(index)
            File.write("tasks.txt", tasks.join)
            puts "Task '#{removed_task.strip}' removed."
        end
    end
end

parser.on('-h', '--help', 'Show help') do
    puts parser
end

parser.parse(ARGV)
