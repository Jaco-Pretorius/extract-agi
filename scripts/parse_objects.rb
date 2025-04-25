# frozen_string_literal: true

require 'optparse'
require 'json'
require 'stringio'
require_relative '../lib/extract_agi'

module ObjectsParser
  LITTLE_ENDIAN_UNSIGNED_SIXTEEN_BIT = 'v'
  UNSIGNED_EIGHT_BIT = 'C'
  SYMMETRIC_ENCRYPTION_KEY = 'Avis Durgan'

  class << self
    def parse_objects(file_path)
      ExtractAgi::File.open(file_path, symmetric_encryption_key: SYMMETRIC_ENCRYPTION_KEY) do |file|
        offset = file.read_u16le
        puts "Offset to words: #{offset}"

        file.seek(offset, IO::SEEK_SET)

        word = String.new
        loop do
          break unless (byte = file.read_u8)

          if byte.zero?
            puts word
            word = String.new
          else
            word << byte.chr
          end
        end
      end
    end
  end
end

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"

  opts.on('-fFILE', '--file=FILE', 'OBJECT file relative path') do |file_path|
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

ObjectsParser.parse_objects(options[:file_path])
