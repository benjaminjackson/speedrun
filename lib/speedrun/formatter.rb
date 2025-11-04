# frozen_string_literal: true

module Speedrun
  module Formatter
    SECONDS_PER_MINUTE = 60
    SECONDS_PER_HOUR = 3600
    BYTES_PER_KB = 1024
    BYTES_PER_MB = 1024 * 1024
    BYTES_PER_GB = 1024 * 1024 * 1024

    def self.format_time(seconds)
      hours = (seconds / SECONDS_PER_HOUR).to_i
      minutes = ((seconds % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE).to_i
      secs = seconds % SECONDS_PER_MINUTE

      format('%02d:%02d:%06.3f', hours, minutes, secs)
    end

    def self.parse_time(time_string)
      hours, minutes, seconds = time_string.split(':').map(&:to_f)
      (hours * SECONDS_PER_HOUR) + (minutes * SECONDS_PER_MINUTE) + seconds
    end

    def self.format_duration(seconds)
      if seconds < SECONDS_PER_MINUTE
        format('%.2fs', seconds)
      elsif seconds < SECONDS_PER_HOUR
        minutes = (seconds / SECONDS_PER_MINUTE).to_i
        secs = seconds % SECONDS_PER_MINUTE
        format('%dm %.1fs', minutes, secs)
      else
        hours = (seconds / SECONDS_PER_HOUR).to_i
        minutes = ((seconds % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE).to_i
        secs = seconds % SECONDS_PER_MINUTE
        format('%dh %dm %ds', hours, minutes, secs.to_i)
      end
    end

    def self.format_filesize(bytes)
      if bytes < BYTES_PER_KB
        format('%d B', bytes)
      elsif bytes < BYTES_PER_MB
        format('%.1f KB', bytes / BYTES_PER_KB.to_f)
      elsif bytes < BYTES_PER_GB
        format('%.1f MB', bytes / BYTES_PER_MB.to_f)
      else
        format('%.1f GB', bytes / BYTES_PER_GB.to_f)
      end
    end
  end
end
