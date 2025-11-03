# frozen_string_literal: true

require "test_helper"

module Ffwd
  class TestCLI < Minitest::Test
    def test_version_command
      output = capture_io do
        CLI.start(['version'])
      end.join

      assert_match(/#{Ffwd::VERSION}/, output)
    end

    def test_trim_command_processes_file
      File.stub :exist?, true do
        trimmer_mock = Minitest::Mock.new
        trimmer_mock.expect :dry_run=, nil, [false]
        trimmer_mock.expect :run, nil

        Trimmer.stub :new, trimmer_mock do
          CLI.start(['trim', 'input.mp4'])
        end

        trimmer_mock.verify
      end
    end

    def test_trim_command_with_output_argument
      File.stub :exist?, true do
        trimmer_mock = Minitest::Mock.new
        trimmer_mock.expect :dry_run=, nil, [false]
        trimmer_mock.expect :run, nil

        Trimmer.stub :new, trimmer_mock do
          CLI.start(['trim', 'input.mp4', 'output.mp4'])
        end

        trimmer_mock.verify
      end
    end

    def test_trim_command_with_noise_option
      File.stub :exist?, true do
        trimmer_mock = Minitest::Mock.new
        trimmer_mock.expect :dry_run=, nil, [false]
        trimmer_mock.expect :run, nil

        Trimmer.stub :new, trimmer_mock do
          CLI.start(['trim', 'input.mp4', '--noise', '-60'])
        end

        trimmer_mock.verify
      end
    end

    def test_trim_command_with_duration_option
      File.stub :exist?, true do
        trimmer_mock = Minitest::Mock.new
        trimmer_mock.expect :dry_run=, nil, [false]
        trimmer_mock.expect :run, nil

        Trimmer.stub :new, trimmer_mock do
          CLI.start(['trim', 'input.mp4', '--duration', '2.0'])
        end

        trimmer_mock.verify
      end
    end

    def test_trim_command_with_dry_run_flag
      File.stub :exist?, true do
        trimmer_mock = Minitest::Mock.new
        trimmer_mock.expect :dry_run=, nil, [true]
        trimmer_mock.expect :run, nil

        Trimmer.stub :new, trimmer_mock do
          CLI.start(['trim', 'input.mp4', '--dry-run'])
        end

        trimmer_mock.verify
      end
    end

    def test_trim_command_validates_input_file_exists
      File.stub :exist?, false do
        output = capture_io do
          begin
            CLI.start(['trim', 'nonexistent.mp4'])
          rescue SystemExit
            # Expected
          end
        end.join

        assert_match(/File not found/, output)
      end
    end
  end
end
