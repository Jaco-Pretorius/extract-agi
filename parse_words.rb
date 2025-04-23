# frozen_string_literal: true

require 'optparse'
require 'json'

module WordsParser
  BIG_ENDIAN_UNSIGNED_SIXTEEN_BIT = 'n'
  UNSIGNED_EIGHT_BIT = 'C'

  class << self
    def parse_words(file_path)
      dictionary = {}
      current_word = ''
      File.open(file_path, 'rb') do |file|
        file.seek(1, IO::SEEK_SET)
        file.seek(file.readbyte, IO::SEEK_SET)
        loop do
          break unless (byte = file.read(1))

          prefix_length = byte.unpack1(UNSIGNED_EIGHT_BIT)
          current_word = current_word[0, prefix_length]
          current_word << parse_word(file)

          word_number_bytes = file.read(2)
          break unless word_number_bytes

          word_number = word_number_bytes.unpack1(BIG_ENDIAN_UNSIGNED_SIXTEEN_BIT)
          dictionary[word_number] ||= []
          dictionary[word_number] << current_word
        end
      end

      dictionary
    end

    private

    def parse_word(file)
      word = String.new
      loop do
        break unless (byte = file.read(1))

        value = byte.unpack1(UNSIGNED_EIGHT_BIT)
        if value > 127
          word << ((value - 128) ^ 0x7F).chr
          break
        else
          word << (value ^ 0x7F).chr
        end
      end
      word
    end
  end
end

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

dictionary = WordsParser.parse_words(options[:file_path])
puts JSON.pretty_generate(dictionary.sort.to_h)
