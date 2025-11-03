# frozen_string_literal: true

module Ffwd
  module FFmpeg
    FREEZE_START_PATTERN = /freeze_start:\s*([\d.]+)/
    FREEZE_END_PATTERN = /freeze_end:\s*([\d.]+)/

    def self.parse_duration(output)
      output.strip.to_f
    end

    def self.parse_freezes(output)
      regions = []
      freeze_start = nil

      output.each_line do |line|
        if line =~ FREEZE_START_PATTERN
          freeze_start = ::Regexp.last_match(1).to_f
        elsif line =~ FREEZE_END_PATTERN && freeze_start
          freeze_end = ::Regexp.last_match(1).to_f
          regions << [freeze_start, freeze_end]
          freeze_start = nil
        end
      end

      regions
    end
  end
end
