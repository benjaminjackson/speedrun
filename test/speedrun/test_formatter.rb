# frozen_string_literal: true

require "test_helper"

module Speedrun
  class TestFormatter < Minitest::Test
    def test_format_time_zero
      assert_equal "00:00:00.000", Formatter.format_time(0)
    end

    def test_format_time_with_hours_minutes_seconds
      assert_equal "01:01:01.500", Formatter.format_time(3661.5)
    end

    def test_format_duration_under_one_minute
      assert_equal "45.00s", Formatter.format_duration(45)
    end

    def test_format_duration_with_minutes
      assert_equal "1m 30.0s", Formatter.format_duration(90)
    end

    def test_format_duration_with_hours
      assert_equal "1h 1m 5s", Formatter.format_duration(3665)
    end

    def test_format_filesize_bytes
      assert_equal "512 B", Formatter.format_filesize(512)
    end

    def test_format_filesize_kilobytes
      assert_equal "1.5 KB", Formatter.format_filesize(1536)
    end

    def test_format_filesize_megabytes
      assert_equal "1.0 MB", Formatter.format_filesize(1048576)
    end

    def test_format_filesize_gigabytes
      assert_equal "2.5 GB", Formatter.format_filesize(2684354560)
    end

    def test_parse_time_zero
      assert_equal 0.0, Formatter.parse_time("00:00:00.000")
    end

    def test_parse_time_with_hours_minutes_seconds
      assert_equal 3661.5, Formatter.parse_time("01:01:01.500")
    end

    def test_parse_time_simple
      assert_equal 83.45, Formatter.parse_time("00:01:23.450")
    end
  end
end
