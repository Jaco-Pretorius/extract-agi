require 'optparse'
require 'json'

module WordsParser
  BIG_ENDIAN_UNSIGNED_SIXTEEN_BIT = "n"
  UNSIGNED_EIGHT_BIT = "C"

  def self.parse_words(file_path)
    dictionary = {}
    previous_word, current_word = "", ""
    File.open(file_path, "rb") do |file|
      file.seek(1, IO::SEEK_SET)
      initial_position = file.readbyte

      file.seek(initial_position, IO::SEEK_SET)
      loop do
        previous_word = current_word
        current_word = ""

        byte = file.read(1)
        break if file.eof?

        prefix_length = byte.unpack1(UNSIGNED_EIGHT_BIT)
        current_word = previous_word[0, prefix_length]

        loop do
          byte = file.read(1)
          break if file.eof?

          value = byte.unpack1(UNSIGNED_EIGHT_BIT)
          if value < 32
            current_word << (value ^ 0x7F).chr
          elsif value == 95
            current_word << " "
          elsif value > 127
            current_word << ((value - 128) ^ 0x7F).chr
            break
          else
            # Ignore
          end
        end

        word_number_bytes = file.read(2)
        break unless word_number_bytes

        word_number = word_number_bytes.unpack1(BIG_ENDIAN_UNSIGNED_SIXTEEN_BIT)
        dictionary[word_number] ||= []
        dictionary[word_number] << current_word
      end
    end

    dictionary
  end
end

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options]"

  opts.on("-fFILE", "--file=FILE", "WORDS.TOK file relative path") do |file_path|
    options[:file_path] = file_path
  end

  opts.on("-h", "--help", "Prints this help") do
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

dictionary = WordsParser::parse_words(options[:file_path])
puts JSON.pretty_generate(dictionary.sort.to_h)
