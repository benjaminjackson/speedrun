# frozen_string_literal: true

require_relative "ffwd/version"
require_relative "ffwd/formatter"
require_relative "ffwd/ffmpeg"
require_relative "ffwd/trimmer"

module Ffwd
  class Error < StandardError; end
end
