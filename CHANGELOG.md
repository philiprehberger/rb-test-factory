# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-04-16

### Added
- `build_list(name, count, **overrides)` for generating multiple objects

### Changed
- `build_list` now raises `ArgumentError` for negative `count` values

## [0.2.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.2.0] - 2026-03-30

### Added

- Factory callbacks via `after_build` — run hooks after building an object
- Transient attributes via `transient` block — declare attributes used in callbacks but excluded from the final hash
- Associations via `association` — build nested objects using other registered factories

## [0.1.9] - 2026-03-26

### Changed

- Add Sponsor badge and fix License link format in README

## [0.1.8] - 2026-03-24

### Changed
- Expand test coverage to 50+ examples covering edge cases and error paths

## [0.1.7] - 2026-03-24

### Fixed
- Fix README one-liner to remove trailing period and match gemspec summary

## [0.1.6] - 2026-03-24

### Fixed
- Remove inline comments from Development section to match template

## [0.1.5] - 2026-03-22

### Changed
- Expand test coverage

## [0.1.4] - 2026-03-21

### Fixed
- Standardize Installation section in README

## [0.1.3] - 2026-03-16

### Added
- Add License badge to README
- Add bug_tracker_uri to gemspec

## [0.1.2] - 2026-03-13

### Fixed
- Fix RuboCop ExtraSpacing offense in gemspec metadata

## [0.1.1] - 2026-03-13

### Added
- Add Requirements section to README

## [0.1.0] - 2026-03-13

### Added
- Initial release
- Factory definitions with default attributes
- Trait support for field overrides
- Thread-safe auto-incrementing sequences
- `build` and `build_list` convenience methods
- Module-level DSL with global registry
