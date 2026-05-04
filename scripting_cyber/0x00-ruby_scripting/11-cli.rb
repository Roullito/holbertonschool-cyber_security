#!/usr/bin/env ruby

require 'optparse'

TASKS_FILE = 'tasks.txt'

def load_tasks
  return [] unless File.exist?(TASKS_FILE)

  File.readlines(TASKS_FILE, chomp: true)
end

def save_tasks(tasks)
  File.open(TASKS_FILE, 'w') do |file|
    tasks.each do |task|
      file.puts task
    end
  end
end

def add_task(task)
  tasks = load_tasks
  tasks << task
  save_tasks(tasks)
  puts "Task '#{task}' added."
end

def list_tasks
  tasks = load_tasks

  tasks.each_with_index do |task, index|
    puts "#{index + 1}. #{task}"
  end
end

def remove_task(index)
  tasks = load_tasks
  task_index = index.to_i - 1

  if task_index >= 0
    if task_index < tasks.length
      removed_task = tasks.delete_at(task_index)
      save_tasks(tasks)
      puts "Task '#{removed_task}' removed."
    end
  end
end

options = {}

parser = OptionParser.new do |opts|
  opts.banner = 'Usage: cli.rb [options]'

  opts.on('-a', '--add TASK', 'Add a new task') do |task|
    options[:add] = task
  end

  opts.on('-l', '--list', 'List all tasks') do
    options[:list] = true
  end

  opts.on('-r', '--remove INDEX', 'Remove a task by index') do |index|
    options[:remove] = index
  end

  opts.on('-h', '--help', 'Show help') do
    puts opts
    exit
  end
end

parser.parse!

if options[:add]
  add_task(options[:add])
elsif options[:list]
  list_tasks
elsif options[:remove]
  remove_task(options[:remove])
else
  puts parser
end