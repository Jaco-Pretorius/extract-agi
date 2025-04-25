# frozen_string_literal: true

require 'optparse'
require 'json'
require 'stringio'

module ObjectsParser
  LITTLE_ENDIAN_UNSIGNED_SIXTEEN_BIT = 'v'
  UNSIGNED_EIGHT_BIT = 'C'
  SYMMETRIC_ENCRYPTION_KEY = 'Avis Durgan'

  class << self
    def parse_objects(file_path)
      decrypt_file(file_path) do |file|
        offset = file.read(2).unpack1(LITTLE_ENDIAN_UNSIGNED_SIXTEEN_BIT)
        puts "Offset to words: #{offset}"

        file.seek(offset, IO::SEEK_SET)

        word = String.new
        loop do
          break unless (byte = file.read(1))

          value = byte.unpack1(UNSIGNED_EIGHT_BIT)
          if value.zero?
            puts word
            word = String.new
          else
            word << value.chr
          end
        end
      end
    end

    private

    def decrypt_file(file_path)
      File.open(file_path, 'rb') do |file|
        transformed = String.new
        encryption_key_index = 0

        until file.eof?
          byte = file.read(1).unpack1(UNSIGNED_EIGHT_BIT)
          mutated = byte ^ SYMMETRIC_ENCRYPTION_KEY[encryption_key_index].ord
          encryption_key_index = (encryption_key_index + 1) % SYMMETRIC_ENCRYPTION_KEY.length
          transformed << [mutated].pack(UNSIGNED_EIGHT_BIT)
        end

        yield StringIO.new(transformed)
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
