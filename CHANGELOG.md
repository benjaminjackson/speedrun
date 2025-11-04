# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-11-03

### Added
- Progress tracking with real-time progress bars during video processing
- Quiet mode to suppress verbose output
- Enhanced time parsing and formatting utilities

## [0.1.0] - 2025-11-03

### Added
- Initial release of speedrun gem
- Core video trimming functionality to detect and remove freeze/low-motion regions
- FFmpeg integration for video processing
- CLI interface with Thor framework
- Time, duration, and filesize formatters
- Freeze detection using motion vectors
- Video segment extraction and concatenation
- Dry-run mode for testing without processing
- Configurable noise threshold for motion detection
- Progress feedback during video processing
- Comprehensive test suite with mocked FFmpeg calls
