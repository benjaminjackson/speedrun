# frozen_string_literal: true

require 'thor'

module Speedrun
  class CLI < Thor
    desc "version", "Display version"
    def version
      puts "speedrun version #{Speedrun::VERSION}"
    end

    desc "trim INPUT [OUTPUT]", "Trim freeze/low-motion regions from video"
    option :noise, type: :numeric, aliases: '-n', default: -70, desc: "Noise tolerance in dB (less negative = more cuts)"
    option :duration, type: :numeric, aliases: '-d', default: 1.0, desc: "Minimum freeze duration to remove in seconds"
    option :'dry-run', type: :boolean, default: false, desc: "Preview without processing"
    option :quiet, type: :boolean, aliases: '-q', default: false, desc: "Minimal output"
    def trim(input_file, output_file = nil)
      unless File.exist?(input_file)
        puts "Error: File not found: #{input_file}"
        exit 1
      end

      trimmer = Trimmer.new(
        input_file,
        output_file,
        noise_threshold: options[:noise],
        min_duration: options[:duration],
        quiet: options[:quiet]
      )

      trimmer.dry_run = options[:'dry-run']
      trimmer.run
    rescue => e
      puts "Error: #{e.message}"
      exit 1
    end

    default_task :trim
  end
end
