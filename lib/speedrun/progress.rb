# frozen_string_literal: true

require "ruby-progressbar"

module Speedrun
  module Progress
    def self.create(title:, total:, quiet: false)
      return nil if quiet

      ProgressBar.create(
        title: title,
        total: total,
        format: "%t: |%B| %p%%"
      )
    end
  end
end
