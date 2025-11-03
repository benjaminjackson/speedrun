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

    def test_get_duration_calls_ffprobe_and_returns_duration
      fixture_output = load_fixture("ffprobe_duration.txt")

      File.stub :exist?, true do
        FFmpeg.stub :`, fixture_output do
          duration = FFmpeg.get_duration("test.mp4")
          assert_equal 120.5, duration
        end
      end
    end

    def test_get_duration_raises_error_if_file_not_found
      assert_raises(ArgumentError) do
        FFmpeg.get_duration("nonexistent.mp4")
      end
    end

    def test_detect_freezes_returns_parsed_freeze_regions
      fixture_output = load_fixture("ffmpeg_freezedetect_multiple.txt")

      File.stub :exist?, true do
        FFmpeg.stub :`, fixture_output do
          freezes = FFmpeg.detect_freezes("test.mp4", noise_threshold: -70, min_duration: 1.0)
          assert_equal [[10.0, 15.0], [45.2, 50.7], [90.0, 93.0]], freezes
        end
      end
    end

    def test_detect_freezes_raises_error_if_file_not_found
      assert_raises(ArgumentError) do
        FFmpeg.detect_freezes("nonexistent.mp4")
      end
    end

    def test_extract_and_concat_raises_error_if_input_file_not_found
      assert_raises(ArgumentError) do
        FFmpeg.extract_and_concat("nonexistent.mp4", "output.mp4", [[0.0, 10.0]])
      end
    end

    def test_extract_and_concat_raises_error_if_no_regions_to_keep
      File.stub :exist?, true do
        assert_raises(ArgumentError) do
          FFmpeg.extract_and_concat("test.mp4", "output.mp4", [])
        end
      end
    end
  end
end
