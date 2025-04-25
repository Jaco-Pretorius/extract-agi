# frozen_string_literal: true

module ExtractAgi
  class WordParser
    INDEX_SIZE = 26 * 2
    BIG_ENDIAN_UNSIGNED_SIXTEEN_BIT = 'n'
    UNSIGNED_EIGHT_BIT = 'C'

    def initialize(file_path:)
      @file_path = file_path
    end

    def parse_words
      dictionary = {}
      current_word = ''
      File.open(@file_path, 'rb') do |file|
        file.seek(INDEX_SIZE - 1, IO::SEEK_SET)
        loop do
          prefix_length = file.read(1).unpack1(UNSIGNED_EIGHT_BIT)
          current_word = current_word[0, prefix_length]
          current_word << parse_next_word(file)

          break if current_word.empty?

          word_number = file.read(2).unpack1(BIG_ENDIAN_UNSIGNED_SIXTEEN_BIT)
          dictionary[word_number] ||= []
          dictionary[word_number] << current_word
        end
      end

      dictionary
    end

    def parse_index
      File.open(@file_path, 'rb') do |file|
        ('a'..'z').each_with_object({}) do |letter, index|
          index[letter] = file.read(2).unpack1(BIG_ENDIAN_UNSIGNED_SIXTEEN_BIT)
        end
      end
    end

    private

    def parse_next_word(file)
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
