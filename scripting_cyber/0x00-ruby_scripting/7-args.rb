#!/usr/bin/env ruby

def print_arguments
    if ARGV.empty?
        puts "No arguments provided."
    else
        puts "Arguments:"
        ARGV.each_with_index do |x, index|
            puts "#{index + 1}. #{x}"
        end
    end
end
