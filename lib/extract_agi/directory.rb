# frozen_string_literal: true

module ExtractAgi
  class Directory
    attr_reader :index, :volume, :offset

    def initialize(index:, volume:, offset:)
      @index = index
      @volume = volume
      @offset = offset
    end

    def resource_exists?
      !volume.nil? && !offset.nil?
    end
  end
end
