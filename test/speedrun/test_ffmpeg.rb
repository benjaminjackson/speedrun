# frozen_string_literal: true

require "test_helper"
require "ostruct"

module Speedrun
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

      mock_stdin = Minitest::Mock.new
      mock_stdin.expect(:close, nil)

      mock_wait_thr = Minitest::Mock.new
      mock_wait_thr.expect(:value, nil)

      File.stub :exist?, true do
        Open3.stub :popen3, ->(*args, &block) {
          mock_stderr = StringIO.new(fixture_output)
          block.call(mock_stdin, nil, mock_stderr, mock_wait_thr)
        } do
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

    def test_detect_freezes_calls_progress_block_during_execution
      # This test verifies that detect_freezes processes output progressively (streaming)
      # and calls the progress block with percentages
      progress_calls = []

      File.stub :exist?, true do
        # We'll stub Open3.popen3 to simulate ffmpeg output
        require 'open3'

        # Create a mock stderr that yields lines
        stderr_data = [
          "Duration: 00:01:40.00, start: 0.000000",
          "frame=  100 fps=50 q=-1.0 size=N/A time=00:00:10.00",
          "frame=  500 fps=50 q=-1.0 size=N/A time=00:00:50.00",
          "[Parsed_freezedetect_0 @ 0x123] freeze_start: 45.2",
          "frame= 1000 fps=50 q=-1.0 size=N/A time=00:01:40.00",
          "[Parsed_freezedetect_0 @ 0x123] freeze_end: 50.7"
        ].join("\n")

        # Create a mock wait thread
        mock_wait_thr = Minitest::Mock.new
        mock_wait_thr.expect(:value, nil)

        # Create a mock stdin
        mock_stdin = Minitest::Mock.new
        mock_stdin.expect(:close, nil)

        Open3.stub :popen3, ->(*args, &block) {
          mock_stderr = StringIO.new(stderr_data)
          block.call(mock_stdin, nil, mock_stderr, mock_wait_thr)
        } do
          _freezes = FFmpeg.detect_freezes("test.mp4") do |progress|
            progress_calls << progress
          end

          # Verify the block was called with progress values
          assert progress_calls.length > 0, "Progress block should be called at least once"
          assert progress_calls.all? { |p| p >= 0 && p <= 100 }, "Progress values should be between 0 and 100"
        end
      end
    end

    def test_extract_and_concat_calls_progress_block_during_execution
      # This test verifies that extract_and_concat processes output progressively (streaming)
      # and calls the progress block with percentages
      progress_calls = []

      require 'open3'

      stderr_data = [
        "Duration: 00:01:00.00, start: 0.000000",
        "frame=  100 fps=50 q=-1.0 size=N/A time=00:00:20.00",
        "frame=  150 fps=50 q=-1.0 size=N/A time=00:00:30.00",
        "frame=  300 fps=50 q=-1.0 size=N/A time=00:01:00.00"
      ].join("\n")

      # Mock the Tempfile to avoid actual file creation
      mock_tempfile = Minitest::Mock.new
      mock_tempfile.expect(:puts, nil, [String])
      mock_tempfile.expect(:puts, nil, [String])
      mock_tempfile.expect(:puts, nil, [String])
      mock_tempfile.expect(:flush, nil)
      mock_tempfile.expect(:path, "/tmp/test.txt")

      mock_wait_thr = Minitest::Mock.new
      mock_wait_thr.expect(:value, OpenStruct.new(success?: true))

      mock_stdin = Minitest::Mock.new
      mock_stdin.expect(:close, nil)

      File.stub :exist?, true do
        File.stub :absolute_path, "/abs/path/test.mp4" do
          Tempfile.stub :create, ->(*args, &block) { block.call(mock_tempfile) } do
            Open3.stub :popen3, ->(*args, &block) {
              mock_stderr = StringIO.new(stderr_data)
              block.call(mock_stdin, nil, mock_stderr, mock_wait_thr)
            } do
              result = FFmpeg.extract_and_concat("test.mp4", "output.mp4", [[0.0, 10.0]]) do |progress|
                progress_calls << progress
              end

              # Verify the block was called with progress values
              assert progress_calls.length > 0, "Progress block should be called at least once"
              assert progress_calls.all? { |p| p >= 0 && p <= 100 }, "Progress values should be between 0 and 100"
              assert result, "extract_and_concat should return true on success"
            end
          end
        end
      end
    end
  end
end
