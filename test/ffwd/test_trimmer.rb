# frozen_string_literal: true

require "test_helper"

module Ffwd
  class TestTrimmer < Minitest::Test
    def test_initializes_with_input_file
      File.stub :exist?, true do
        trimmer = Trimmer.new("input.mp4")
        assert_instance_of Trimmer, trimmer
      end
    end

    def test_raises_error_if_file_missing
      File.stub :exist?, false do
        assert_raises(ArgumentError) do
          Trimmer.new("missing.mp4")
        end
      end
    end

    def test_generates_default_output_filename
      File.stub :exist?, true do
        trimmer = Trimmer.new("video.mp4")
        assert_equal "video-trimmed.mp4", trimmer.output_file
      end
    end

    def test_accepts_custom_output_filename
      File.stub :exist?, true do
        trimmer = Trimmer.new("input.mp4", "custom-output.mp4")
        assert_equal "custom-output.mp4", trimmer.output_file
      end
    end

    def test_accepts_noise_threshold_option
      File.stub :exist?, true do
        trimmer = Trimmer.new("input.mp4", noise_threshold: -60)
        assert_equal(-60, trimmer.instance_variable_get(:@noise_threshold))
      end
    end

    def test_accepts_min_duration_option
      File.stub :exist?, true do
        trimmer = Trimmer.new("input.mp4", min_duration: 2.0)
        assert_equal 2.0, trimmer.instance_variable_get(:@min_duration)
      end
    end

    def test_calculate_keep_regions_with_no_freezes
      File.stub :exist?, true do
        trimmer = Trimmer.new("input.mp4")
        keep_regions = trimmer.send(:calculate_keep_regions, [], 100.0)
        assert_equal [[0.0, 100.0]], keep_regions
      end
    end

    def test_calculate_keep_regions_with_freeze_at_start
      File.stub :exist?, true do
        trimmer = Trimmer.new("input.mp4")
        freeze_regions = [[0.0, 10.0]]
        keep_regions = trimmer.send(:calculate_keep_regions, freeze_regions, 100.0)
        assert_equal [[10.0, 100.0]], keep_regions
      end
    end

    def test_calculate_keep_regions_with_freeze_at_end
      File.stub :exist?, true do
        trimmer = Trimmer.new("input.mp4")
        freeze_regions = [[90.0, 100.0]]
        keep_regions = trimmer.send(:calculate_keep_regions, freeze_regions, 100.0)
        assert_equal [[0.0, 90.0]], keep_regions
      end
    end

    def test_calculate_keep_regions_with_freeze_in_middle
      File.stub :exist?, true do
        trimmer = Trimmer.new("input.mp4")
        freeze_regions = [[40.0, 60.0]]
        keep_regions = trimmer.send(:calculate_keep_regions, freeze_regions, 100.0)
        assert_equal [[0.0, 40.0], [60.0, 100.0]], keep_regions
      end
    end

    def test_calculate_keep_regions_with_multiple_freezes
      File.stub :exist?, true do
        trimmer = Trimmer.new("input.mp4")
        freeze_regions = [[10.0, 20.0], [50.0, 60.0]]
        keep_regions = trimmer.send(:calculate_keep_regions, freeze_regions, 100.0)
        assert_equal [[0.0, 10.0], [20.0, 50.0], [60.0, 100.0]], keep_regions
      end
    end

    def test_calculate_keep_regions_with_adjacent_freezes
      File.stub :exist?, true do
        trimmer = Trimmer.new("input.mp4")
        freeze_regions = [[10.0, 20.0], [20.0, 30.0]]
        keep_regions = trimmer.send(:calculate_keep_regions, freeze_regions, 100.0)
        assert_equal [[0.0, 10.0], [30.0, 100.0]], keep_regions
      end
    end
  end
end
