# frozen_string_literal: true

require 'stringio'

module ExtractAgi
  class File
    class << self
      def open(file_path)
        yield new(StringIO.new(::File.binread(file_path)))
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
  end
end
