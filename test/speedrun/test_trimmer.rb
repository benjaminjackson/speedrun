# frozen_string_literal: true

require "test_helper"

module Speedrun
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

    def test_dry_run_mode_enabled
      File.stub :exist?, true do
        trimmer = Trimmer.new("input.mp4")
        trimmer.dry_run = true
        assert trimmer.dry_run?
      end
    end

    def test_run_with_no_freezes_copies_file
      File.stub :exist?, true do
        FFmpeg.stub :get_duration, 100.0 do
          FFmpeg.stub :detect_freezes, [] do
            FileUtils.stub :cp, nil do
              trimmer = Trimmer.new("input.mp4")

              # Capture output
              output = capture_io { trimmer.run }.join

              assert_match(/No freeze regions detected/, output)
            end
          end
        end
      end
    end

    def test_run_raises_error_if_all_content_removed
      File.stub :exist?, true do
        FFmpeg.stub :get_duration, 100.0 do
          FFmpeg.stub :detect_freezes, [[0.0, 100.0]] do
            trimmer = Trimmer.new("input.mp4")

            error = assert_raises(RuntimeError) { trimmer.run }
            assert_match(/All video content would be removed/, error.message)
          end
        end
      end
    end

    def test_dry_run_outputs_analysis_without_processing
      File.stub :exist?, true do
        FFmpeg.stub :get_duration, 100.0 do
          FFmpeg.stub :detect_freezes, [[40.0, 60.0]] do
            trimmer = Trimmer.new("input.mp4")
            trimmer.dry_run = true

            output = capture_io { trimmer.run }.join

            assert_match(/DRY RUN/, output)
            assert_match(/Found 1 freeze/, output)
          end
        end
      end
    end

    def test_run_processes_video_when_not_dry_run
      File.stub :exist?, true do
        File.stub :size, 1024000 do
          FFmpeg.stub :get_duration, 100.0 do
            FFmpeg.stub :detect_freezes, [[40.0, 60.0]] do
              FFmpeg.stub :extract_and_concat, ->(input, output, regions, quiet: false, &block) { true } do
                trimmer = Trimmer.new("input.mp4", "output.mp4")

                output = capture_io { trimmer.run }.join

                assert_match(/Complete!/, output)
                assert_match(/output.mp4/, output)
                assert_match(/File size:/, output)
              end
            end
          end
        end
      end
    end

    def test_run_calls_extract_and_concat_with_correct_parameters
      keep_regions = [[0.0, 40.0], [60.0, 100.0]]

      File.stub :exist?, true do
        File.stub :size, 1024000 do
          FFmpeg.stub :get_duration, 100.0 do
            FFmpeg.stub :detect_freezes, [[40.0, 60.0]] do
              extract_called = false
              extract_input = nil
              extract_output = nil
              extract_regions = nil

              FFmpeg.stub :extract_and_concat, ->(input, output, regions, quiet: false, &block) {
                extract_called = true
                extract_input = input
                extract_output = output
                extract_regions = regions
                true
              } do
                trimmer = Trimmer.new("input.mp4", "output.mp4")
                capture_io { trimmer.run }

                assert extract_called, "extract_and_concat should be called"
                assert_equal "input.mp4", extract_input
                assert_equal "output.mp4", extract_output
                assert_equal keep_regions, extract_regions
              end
            end
          end
        end
      end
    end

    def test_accepts_quiet_option
      File.stub :exist?, true do
        trimmer = Trimmer.new("input.mp4", quiet: true)
        assert_instance_of Trimmer, trimmer
        # Verify the quiet flag is stored (we'll check its behavior in later tests)
        assert_respond_to trimmer, :quiet?
        assert trimmer.quiet?
      end
    end
  end
end
