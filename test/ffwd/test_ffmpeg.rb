# frozen_string_literal: true

require "test_helper"

module Ffwd
  class TestFFmpeg < Minitest::Test
    def test_parse_duration_from_valid_output
      output = load_fixture("ffprobe_duration.txt")
      duration = FFmpeg.parse_duration(output)
      assert_equal 120.5, duration
    end

    def test_parse_duration_returns_zero_for_malformed_output
      output = "N/A\n"
      duration = FFmpeg.parse_duration(output)
      assert_equal 0.0, duration
    end

    def test_parse_freezes_with_no_freezes
      output = load_fixture("ffmpeg_freezedetect_none.txt")
      freezes = FFmpeg.parse_freezes(output)
      assert_equal [], freezes
    end

    def test_parse_freezes_with_single_freeze
      output = load_fixture("ffmpeg_freezedetect_single.txt")
      freezes = FFmpeg.parse_freezes(output)
      assert_equal [[45.2, 50.7]], freezes
    end

    def test_parse_freezes_with_multiple_freezes
      output = load_fixture("ffmpeg_freezedetect_multiple.txt")
      freezes = FFmpeg.parse_freezes(output)
      assert_equal [[10.0, 15.0], [45.2, 50.7], [90.0, 93.0]], freezes
    end

    def test_parse_freezes_ignores_unpaired_freeze_start
      output = "[Parsed_freezedetect_0 @ 0x123] freeze_start: 10.0\n"
      freezes = FFmpeg.parse_freezes(output)
      assert_equal [], freezes
    end
  end
end
