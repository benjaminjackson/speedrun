# frozen_string_literal: true

module Ffwd
  class Trimmer
    attr_reader :input_file, :output_file

    def initialize(input_file, output_file = nil, noise_threshold: -70, min_duration: 1.0)
      raise ArgumentError, "File not found: #{input_file}" unless File.exist?(input_file)

      @input_file = input_file
      @output_file = output_file || generate_output_filename(input_file)
      @noise_threshold = noise_threshold
      @min_duration = min_duration
    end

    private

    def generate_output_filename(input_file)
      ext = File.extname(input_file)
      base = File.basename(input_file, ext)
      dir = File.dirname(input_file)

      output = "#{base}-trimmed#{ext}"
      dir == "." ? output : File.join(dir, output)
    end

    def calculate_keep_regions(freeze_regions, video_duration)
      return [[0.0, video_duration]] if freeze_regions.empty?

      keep_regions = []
      current_time = 0.0

      freeze_regions.each do |start_time, end_time|
        if start_time > current_time
          keep_regions << [current_time, start_time]
        end
        current_time = end_time
      end

      keep_regions << [current_time, video_duration] if current_time < video_duration

      keep_regions
    end
  end
end
