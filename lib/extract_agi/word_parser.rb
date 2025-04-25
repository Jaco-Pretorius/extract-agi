# frozen_string_literal: true

require_relative 'file'

module ExtractAgi
  class WordParser
    INDEX_SIZE = 26 * 2
    private_constant :INDEX_SIZE

    def initialize(file_path:)
      @file_path = file_path
    end

    def parse_words
      dictionary = {}
      current_word = ''
      ExtractAgi::File.open(@file_path) do |file|
        file.seek(INDEX_SIZE - 1, IO::SEEK_SET)
        loop do
          prefix_length = file.read_u8
          current_word = current_word[0, prefix_length]
          current_word << parse_next_word(file)

          break if current_word.empty?

          word_number = file.read_u16be
          dictionary[word_number] ||= []
          dictionary[word_number] << current_word
        end
      end

      dictionary
    end

    def parse_index
      ExtractAgi::File.open(@file_path) do |file|
        ('a'..'z').each_with_object({}) do |letter, index|
          index[letter] = file.read_u16be
        end
      end
    end

    private

    def parse_next_word(file)
      word = String.new
      loop do
        break unless (byte = file.read_u8)

        if byte > 127
          word << ((byte - 128) ^ 0x7F).chr
          break
        else
          word << (byte ^ 0x7F).chr
        end
      end
      word
    end
  end
end
