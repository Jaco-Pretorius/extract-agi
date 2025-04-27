# frozen_string_literal: true

require_relative 'file'

module ExtractAgi
  class ObjectParser
    SYMMETRIC_ENCRYPTION_KEY = 'Avis Durgan'
    private_constant :SYMMETRIC_ENCRYPTION_KEY

    def initialize(file_path:)
      @file_path = file_path
    end

    def parse_objects
      ExtractAgi::File.open(file_path, symmetric_encryption_key: SYMMETRIC_ENCRYPTION_KEY) do |file|
        offset_to_names = file.read_u16le
        max_animated_objects = file.read_u8

        (3..offset_to_names).step(3).each do |offset|
          file.seek(offset, IO::SEEK_SET)

          name_offset = file.read_u16le
          starting_room = file.read_u8

          file.seek(name_offset + 3, IO::SEEK_SET)
          word = String.new
          loop do
            byte = file.read_u8

            break if byte.zero?

            word << byte.chr
          end
          puts "object: #{offset / 3 - 1}, name: #{word}, starting_room: #{starting_room}"
        end
      end
    end
  end
end
