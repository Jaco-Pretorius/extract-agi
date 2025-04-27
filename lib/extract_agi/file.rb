# frozen_string_literal: true

require 'stringio'

module ExtractAgi
  class File
    class << self
      def open(file_path, symmetric_encryption_key: nil)
        if symmetric_encryption_key.nil?
          yield new(StringIO.new(::File.binread(file_path)))
        else
          cleartext = String.new
          ::File.open(file_path, 'rb') do |file|
            encryption_key_index = 0

            until file.eof?
              byte = file.read(1).unpack1(UNSIGNED_EIGHT_BIT)
              mutated = byte ^ symmetric_encryption_key[encryption_key_index].ord
              encryption_key_index = (encryption_key_index + 1) % symmetric_encryption_key.length
              cleartext << [mutated].pack(UNSIGNED_EIGHT_BIT)
            end
          end

          yield new(StringIO.new(cleartext))
        end
      end
    end

    UNSIGNED_EIGHT_BIT = 'C'
    BIG_ENDIAN_UNSIGNED_SIXTEEN_BIT = 'n'
    LITTLE_ENDIAN_UNSIGNED_SIXTEEN_BIT = 'v'

    private_constant :UNSIGNED_EIGHT_BIT, :BIG_ENDIAN_UNSIGNED_SIXTEEN_BIT, :LITTLE_ENDIAN_UNSIGNED_SIXTEEN_BIT

    def initialize(io)
      @io = io
    end

    def seek(...)
      @io.seek(...)
    end

    def read_u8
      @io.read(1)&.unpack1(UNSIGNED_EIGHT_BIT)
    end

    def read_u16be
      @io.read(2)&.unpack1(BIG_ENDIAN_UNSIGNED_SIXTEEN_BIT)
    end

    def read_u16le
      @io.read(2)&.unpack1(LITTLE_ENDIAN_UNSIGNED_SIXTEEN_BIT)
    end

    def size
      @io.size
    end
  end
end
