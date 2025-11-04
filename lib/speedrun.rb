# frozen_string_literal: true

require_relative "speedrun/version"
require_relative "speedrun/formatter"
require_relative "speedrun/progress"
require_relative "speedrun/ffmpeg"
require_relative "speedrun/trimmer"
require_relative "speedrun/cli"

module Speedrun
  class Error < StandardError; end
end
