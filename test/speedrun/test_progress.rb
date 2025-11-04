# frozen_string_literal: true

require "test_helper"

module Speedrun
  class TestProgress < Minitest::Test
    def test_create_returns_progress_bar
      bar = Progress.create(title: "Test", total: 100)
      assert_instance_of ProgressBar::Base, bar
      assert_equal 100, bar.total
    end

    def test_create_returns_nil_when_quiet
      bar = Progress.create(title: "Test", total: 100, quiet: true)
      assert_nil bar
    end

    def test_create_uses_custom_format
      bar = Progress.create(title: "Test", total: 100)
      # Verify the progress bar has a format string that includes title and bar
      format = bar.instance_variable_get(:@format)
      assert_match(/%t/, format, "Format should include title placeholder")
      assert_match(/%b/, format, "Format should include bar placeholder")
    end
  end
end
