# ffwd

Automatically detect and remove freeze/low-motion regions from videos using ffmpeg.

## Description

`ffwd` analyzes videos for frozen or low-motion segments (using ffmpeg's `freezedetect` filter) and removes them, stitching together only the active parts. Perfect for cleaning up screen recordings, presentation videos, or any footage with long static periods.

## Installation

Install the gem:

```bash
gem install ffwd
```

Or add to your Gemfile:

```ruby
gem 'ffwd'
```

### Requirements

- Ruby >= 3.2.0
- ffmpeg (with freezedetect filter support)
- ffprobe

Install ffmpeg via your package manager:

```bash
# macOS
brew install ffmpeg

# Ubuntu/Debian
apt-get install ffmpeg

# Arch Linux
pacman -S ffmpeg
```

## Usage

Basic usage:

```bash
ffwd trim input.mp4
```

This creates `input-trimmed.mp4` with frozen segments removed.

### Options

```bash
ffwd trim INPUT [OUTPUT] [options]

Options:
  -n, --noise THRESHOLD        # Noise threshold in dB (default: -70)
  -d, --duration SECONDS       # Minimum freeze duration in seconds (default: 1.0)
  --dry-run                    # Preview without processing
  -q, --quiet                  # Minimal output

Examples:
  ffwd trim video.mp4                                    # Creates video-trimmed.mp4
  ffwd trim video.mp4 output.mp4                         # Custom output name
  ffwd trim video.mp4 --noise -60                        # More sensitive detection
  ffwd trim video.mp4 --duration 2.0                     # Only remove freezes >= 2s
  ffwd trim video.mp4 --dry-run                          # Preview analysis only
```

### Other Commands

```bash
ffwd version                   # Show version
ffwd help                      # Show help
```

## How It Works

1. **Detect:** Uses ffmpeg's `freezedetect` filter to find frozen/low-motion segments
2. **Analyze:** Calculates which portions to keep vs. remove
3. **Extract:** Extracts active segments using ffmpeg
4. **Stitch:** Concatenates segments into final output

## Development

After checking out the repo:

```bash
bin/setup                      # Install dependencies
bundle exec rake test          # Run test suite
bundle exec guard              # Auto-run tests on file changes
```

### Testing

The codebase follows strict TDD with 100% test coverage. All ffmpeg calls are mocked for fast, isolated testing.

```bash
bundle exec rake test          # Run full test suite
```

### Test Structure

- **Unit tests:** All components tested in isolation with mocks
- **Integration tests:** Full workflow with mocked FFmpeg
- **Fixtures:** Sample ffmpeg/ffprobe outputs for realistic testing

## Architecture

```
lib/ffwd/
├── version.rb        # Version constant
├── formatter.rb      # Time/duration/filesize formatters
├── ffmpeg.rb         # FFmpeg command wrappers & parsers
├── trimmer.rb        # Core video processing logic
└── cli.rb            # Thor-based CLI interface
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/benjaminjackson/ffwd.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
