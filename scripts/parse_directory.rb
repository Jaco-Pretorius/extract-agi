# frozen_string_literal: true

require 'optparse'
require 'json'
require_relative '../lib/extract_agi'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"

  opts.on('-fFILE', '--file=FILE', 'DIRECTORY file relative path') do |file_path|
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

ExtractAgi::DirectoryParser.new(file_path: options[:file_path]).parse_directory do |directory|
  if directory.resource_exists?
    puts "Entry #{directory.index} - Volume: #{directory.volume}, Offset: #{directory.offset}"
  else
    puts "Entry #{directory.index} - Resource does not exist"
  end
end
