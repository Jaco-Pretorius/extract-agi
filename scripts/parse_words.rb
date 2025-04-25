# frozen_string_literal: true

require 'optparse'
require 'json'
require_relative '../lib/extract_agi'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"

  opts.on('-fFILE', '--file=FILE', 'WORDS.TOK file relative path') do |file_path|
    options[:file_path] = file_path
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end

begin
  parser.parse!
  mandatory = [:file_path]
  missing = mandatory.select { |param| options[param].nil? }
  unless missing.empty?
    puts "Missing options: #{missing.join(', ')}"
    puts parser
    exit 1
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
  puts e.message
  puts parser
  exit 1
end

raise "File does not exist: #{options[:file_path]}" unless File.exist?(options[:file_path])

parser = ExtractAgi::WordParser.new(file_path: options[:file_path])
index = parser.parse_index
puts JSON.pretty_generate(index)
dictionary = parser.parse_words
puts JSON.pretty_generate(dictionary.sort.to_h)
