# frozen_string_literal: true

require 'shellwords'
require 'tempfile'
require 'open3'

module Speedrun
  module FFmpeg
    FREEZE_START_PATTERN = /freeze_start:\s*([\d.]+)/
    FREEZE_END_PATTERN = /freeze_end:\s*([\d.]+)/
    DURATION_PATTERN = /Duration:\s*(\d{2}):(\d{2}):(\d{2}\.\d+)/
    TIME_PATTERN = /time=(\d{2}):(\d{2}):(\d{2}\.\d+)/

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

    def self.get_duration(file_path)
      raise ArgumentError, "File not found: #{file_path}" unless File.exist?(file_path)

      cmd = [
        'ffprobe',
        '-v', 'error',
        '-show_entries', 'format=duration',
        '-of', 'default=noprint_wrappers=1:nokey=1',
        file_path
      ].shelljoin

      output = `#{cmd}`
      parse_duration(output)
    end

    def self.detect_freezes(file_path, noise_threshold: -70, min_duration: 1.0, quiet: false, &block)
      raise ArgumentError, "File not found: #{file_path}" unless File.exist?(file_path)

      cmd = [
        'ffmpeg',
        '-i', file_path,
        '-vf', "freezedetect=n=#{noise_threshold}dB:d=#{min_duration}",
        '-f', 'null',
        '-'
      ]

      output = String.new
      duration = nil

      Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thr|
        stdin.close

        stderr.each_line do |line|
          output << line

          # Extract duration from first line that contains it
          if duration.nil? && line =~ DURATION_PATTERN
            duration = Formatter.parse_time("#{$1}:#{$2}:#{$3}")
          end

          # Extract current time and calculate progress
          if duration && block_given? && line =~ TIME_PATTERN
            current_time = Formatter.parse_time("#{$1}:#{$2}:#{$3}")
            progress = [(current_time / duration * 100).round, 100].min
            block.call(progress)
          end
        end

        wait_thr.value # Wait for process to complete
      end

      parse_freezes(output)
    end

    def self.extract_and_concat(input_file, output_file, keep_regions, quiet: false, &block)
      raise ArgumentError, "File not found: #{input_file}" unless File.exist?(input_file)
      raise ArgumentError, "No regions to keep" if keep_regions.empty?

      abs_input = File.absolute_path(input_file)

      Tempfile.create(['concat', '.txt']) do |concat_file|
        keep_regions.each do |start_time, end_time|
          concat_file.puts "file '#{abs_input}'"
          concat_file.puts "inpoint #{start_time}"
          concat_file.puts "outpoint #{end_time}"
        end
        concat_file.flush

        cmd = [
          'ffmpeg',
          '-f', 'concat',
          '-safe', '0',
          '-i', concat_file.path,
          '-c', 'copy',
          '-y',
          output_file
        ]

        output = String.new
        duration = nil
        success = false

        Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thr|
          stdin.close

          stderr.each_line do |line|
            output << line

            # Extract duration from first line that contains it
            if duration.nil? && line =~ DURATION_PATTERN
              duration = Formatter.parse_time("#{$1}:#{$2}:#{$3}")
            end

            # Extract current time and calculate progress
            if duration && block_given? && line =~ TIME_PATTERN
              current_time = Formatter.parse_time("#{$1}:#{$2}:#{$3}")
              progress = [(current_time / duration * 100).round, 100].min
              block.call(progress)
            end
          end

          success = wait_thr.value.success?
        end

        raise "FFmpeg failed: #{output}" unless success

        success
      end
    end
  end
end
