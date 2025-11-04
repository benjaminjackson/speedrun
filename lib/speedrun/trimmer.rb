# frozen_string_literal: true

require 'fileutils'

module Speedrun
  class Trimmer
    attr_reader :input_file, :output_file
    attr_accessor :dry_run

    def initialize(input_file, output_file = nil, noise_threshold: -70, min_duration: 1.0, quiet: false)
      raise ArgumentError, "File not found: #{input_file}" unless File.exist?(input_file)

      @input_file = input_file
      @output_file = output_file || generate_output_filename(input_file)
      @noise_threshold = noise_threshold
      @min_duration = min_duration
      @dry_run = false
      @quiet = quiet
    end

    def dry_run?
      @dry_run
    end

    def quiet?
      @quiet
    end

    def run
      output "Input:  #{@input_file}"
      output "Output: #{@output_file}"
      output ""

      # Step 1: Detect freeze regions
      progress_bar = Progress.create(title: "Analyzing video", total: 100, quiet: @quiet)
      freeze_regions = FFmpeg.detect_freezes(
        @input_file,
        noise_threshold: @noise_threshold,
        min_duration: @min_duration,
        quiet: @quiet
      ) do |progress|
        progress_bar&.progress = progress if progress
      end
      progress_bar&.finish

      if freeze_regions.empty?
        output "No freeze regions detected. Copying original video..."
        FileUtils.cp(@input_file, @output_file) unless dry_run?
        return
      end

      # Step 2: Calculate keep regions
      video_duration = FFmpeg.get_duration(@input_file)
      keep_regions = calculate_keep_regions(freeze_regions, video_duration)

      if keep_regions.empty?
        raise "All video content would be removed!"
      end

      # Step 3: Print summary
      print_summary(freeze_regions, keep_regions, video_duration)

      # Step 4: Process or dry-run
      if dry_run?
        output ""
        output "DRY RUN - No files were modified"
      else
        output ""
        progress_bar = Progress.create(title: "Processing video", total: 100, quiet: @quiet)
        FFmpeg.extract_and_concat(@input_file, @output_file, keep_regions, quiet: @quiet) do |progress|
          progress_bar&.progress = progress if progress
        end
        progress_bar&.finish

        output_size = File.size(@output_file)
        output "Complete! Output saved to #{@output_file}"
        output "  File size: #{Formatter.format_filesize(output_size)}"
      end
    end

    private

    def output(message)
      puts message unless @quiet
    end

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

    def print_summary(freeze_regions, keep_regions, video_duration)
      total_removed = freeze_regions.sum { |s, e| e - s }
      total_kept = keep_regions.sum { |s, e| e - s }

      output "Analysis complete:"
      output "  Found #{freeze_regions.length} freeze region#{freeze_regions.length == 1 ? '' : 's'}"
      output "  Keeping #{keep_regions.length} segment#{keep_regions.length == 1 ? '' : 's'} with motion"
      output ""
      output "Summary:"
      output "  Original duration: #{Formatter.format_duration(video_duration)}"
      output "  Keeping:  #{Formatter.format_duration(total_kept)} (#{'%.1f' % (total_kept / video_duration * 100)}%)"
      output "  Removing: #{Formatter.format_duration(total_removed)} (#{'%.1f' % (total_removed / video_duration * 100)}%)"
    end
  end
end
