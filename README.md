# speedrun

Automatically detect and remove freeze/low-motion regions from videos using ffmpeg. Perfect for cleaning up screen recordings, presentation videos, or any footage with long static periods.

## Installation

```bash
gem install speedrun
```

Or add to your Gemfile:

```ruby
gem 'speedrun'
```

**Requirements:** Ruby >= 3.2.0, ffmpeg

Install ffmpeg:
```bash
# macOS
brew install ffmpeg

# Ubuntu/Debian
apt-get install ffmpeg
```

## Usage

Basic usage:

```bash
speedrun trim input.mp4
```

This creates `input-trimmed.mp4` with frozen segments removed.

### Options

```bash
speedrun trim INPUT [OUTPUT] [options]

Options:
  -n, --noise THRESHOLD        # Noise tolerance in dB (default: -70)
  -d, --duration SECONDS       # Minimum freeze duration in seconds (default: 1.0)
  --dry-run                    # Preview without processing
  -q, --quiet                  # Minimal output

Examples:
  speedrun trim video.mp4                                    # Creates video-trimmed.mp4
  speedrun trim video.mp4 output.mp4                         # Custom output name
  speedrun trim video.mp4 --noise -60                        # More sensitive detection
  speedrun trim video.mp4 --duration 2.0                     # Only remove freezes >= 2s
  speedrun trim video.mp4 --dry-run                          # Preview analysis only
```

#### Understanding the Noise Threshold

The `--noise` parameter controls how sensitive freeze detection is to small changes in the video:

- **Less negative values** (like `-60 dB`) = **More sensitive**
  Detects freezes even when there's subtle motion or slight changes
  Use when you want to catch nearly-static sections

- **More negative values** (like `-80 dB`) = **Less sensitive**
  Only detects freezes when frames are nearly identical
  Use when you want to preserve sections with minimal motion

The default of `-70 dB` works well for most screen recordings. If you're getting false positives (motion incorrectly flagged as frozen), try `-80 dB`. If freezes are being missed, try `-60 dB`.

### Other Commands

```bash
speedrun version                   # Show version
speedrun help                      # Show help
```

## How It Works

1. **Detect:** Uses ffmpeg's `freezedetect` filter to find frozen/low-motion segments
2. **Analyze:** Calculates which portions to keep vs. remove
3. **Extract:** Extracts active segments using ffmpeg
4. **Stitch:** Concatenates segments into final output

## License

MIT License. See [LICENSE](LICENSE) or https://opensource.org/licenses/MIT
