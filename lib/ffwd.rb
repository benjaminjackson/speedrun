# frozen_string_literal: true

require_relative "ffwd/version"
require_relative "ffwd/formatter"
require_relative "ffwd/ffmpeg"
require_relative "ffwd/trimmer"
require_relative "ffwd/cli"

module Ffwd
  class Error < StandardError; end
end
