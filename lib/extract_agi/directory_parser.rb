# frozen_string_literal: true

require_relative 'file'
require_relative 'directory'

module ExtractAgi
  class DirectoryParser
    def initialize(file_path:)
      @file_path = file_path
    end

    def parse_directory
      ExtractAgi::File.open(@file_path) do |file|
        (0...(file.size / 3)).each do |index|
          file.seek(index * 3, IO::SEEK_SET)

          byte1 = file.read_u8
          byte2 = file.read_u8
          byte3 = file.read_u8

          if [byte1, byte2, byte3].any? { |byte| byte != 0xFF }
            volume = byte1 >> 4
            offset = ((byte1 & 0x0F) << 16) + (byte2 << 8) + byte3

            yield Directory.new(index: index, volume: volume, offset: offset)
          else
            yield Directory.new(index: index, volume: nil, offset: nil)
          end
        end
      end
    end
  end
end
