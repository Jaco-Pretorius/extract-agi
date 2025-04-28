# frozen_string_literal: true

require 'optparse'
require_relative '../lib/extract_agi'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"

  opts.on('-fFILE', '--file=FILE', 'VIEW file relative path') do |file_path|
    options[:file_path] = file_path
  end

  opts.on('-pPATH', '--path=PATH', 'Path of where the AGI VOL files are located') do |agi_path|
    options[:agi_path] = agi_path
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end

begin
  parser.parse!
  mandatory = %i[file_path agi_path]
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
raise "Path does not exist: #{options[:agi_path]}" unless Dir.exist?(options[:agi_path])

ExtractAgi::DirectoryParser.new(file_path: options[:file_path]).parse_directory do |directory|
  if directory.resource_exists?
    ExtractAgi::File.open(::File.join(options[:agi_path], "VOL.#{directory.volume}")) do |file|
      file.seek(directory.offset, IO::SEEK_SET)

      signature = file.read_u16be
      raise "Unexpected signature in volume file: #{signature}" unless signature == 0x1234

      file.read_u8 # volume number
      file.read_u16le # resource size
      file.read_u8 # Unknown view header byte1
      file.read_u8 # Unknown view header byte2

      number_of_loops = file.read_u8
      file.read_u16le # Description position (if not zero)

      loops = (0...number_of_loops).each_with_object({}) do |loop_index, result|
        result[loop_index] = file.read_u16le + directory.offset + 5 # 5 is view header size before the loops start
      end

      loops.each do |loop_index, loop_offset|
        file.seek(loop_offset, IO::SEEK_SET)
        number_of_cels = file.read_u8

        loop_positions = (0...number_of_cels).each_with_object({}) do |cel_index, result|
          result[cel_index] = file.read_u16le + loop_offset
        end

        (0...number_of_cels).each do |cel_index|
          file.seek(loop_positions[cel_index], IO::SEEK_SET)

          cel_width = file.read_u8
          cel_height = file.read_u8
          cel_settings = file.read_u8
          cel_mirror = cel_settings >> 4
          cel_transparency = cel_settings & 0x0F

          bitmap = Array.new(cel_height) { Array.new(cel_width * 2) }
          row = 0
          col = 0

          end_of_cel = false
          until end_of_cel
            pixel = file.read_u8
            if pixel.zero?
              row += 1
              col = 0
              next if (end_of_cel = (row == cel_height))
            end

            color_index = pixel >> 4
            number_of_pixels = pixel & 0x0F

            raise 'color index invalid' if color_index.negative? || color_index > 15

            color_index = 16 if color_index == cel_transparency

            bitmap[row][col] = color_index
            (number_of_pixels * 2).times do
              col += 1
              bitmap[row][col] = color_index
            end
          end

          png = ChunkyPNG::Image.new(bitmap[0].size, bitmap.size, ChunkyPNG::Color::TRANSPARENT)
          (0...bitmap.size).each do |x|
            (0...bitmap[0].size).each do |y|
              png[y, x] = ExtractAgi::COLOR_TABLE[bitmap[x][y]] if bitmap[x][y]
            end
          end
          png.save("view_#{directory.index}_loop_#{loop_index}_cel_#{cel_index}.png")
        end
      end
    end
  end
end
