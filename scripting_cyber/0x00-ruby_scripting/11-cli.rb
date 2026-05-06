#!/usr/bin/env ruby

require 'optparse'

TASKS_FILE = 'tasks.txt'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: cli.rb [options]"

  opts.on("-a", "--add TASK", "Add a new task") do |task|
    options[:add] = task
  end

  opts.on("-l", "--list", "List all tasks") do
    options[:list] = true
  end

  opts.on("-r", "--remove INDEX", Integer, "Remove a task by index") do |index|
    options[:remove] = index
  end

  opts.on("-h", "--help", "Show help") do
    puts opts
    exit
  end
end.parse!

if options[:add]
  File.open(TASKS_FILE, 'a') do |file|
    file.puts options[:add]
  end
  puts "Task '#{options[:add]}' added."
elsif options[:list]
  if File.exist?(TASKS_FILE) && !File.zero?(TASKS_FILE)
    count = 1
    File.foreach(TASKS_FILE) do |line|
      puts "    #{count}. #{line.strip}"
      count += 1
    end
  end
elsif options[:remove]
  if File.exist?(TASKS_FILE)
    tasks = File.readlines(TASKS_FILE)
    index = options[:remove] - 1

    if index >= 0 && index < tasks.length
      removed_task = tasks[index].strip
      tasks.delete_at(index)

      File.write(TASKS_FILE, tasks.join)
      puts "Task '#{removed_task}' removed."
    else
      puts "Invalid task index."
    end
  end
end
