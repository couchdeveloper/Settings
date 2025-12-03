# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-03

### Added
- Initial release of Settings framework
- `@Settings` macro for creating type-safe UserDefaults containers
- `@Setting` macro for declaring individual properties with automatic key generation
- Support for all property list native types (Bool, Int, Float, Double, String, Date, Data, URL, Array, Dictionary)
- Automatic Codable support with JSON and PropertyList encoding strategies
- Custom encoder/decoder support for advanced use cases
- Prefix-based key namespacing to avoid conflicts
- Suite name support for app groups and shared containers
- Reactive programming support:
  - Combine publishers via projected values (`$property.publisher`)
  - AsyncSequence streams (`$property.stream`)
  - Key-path observation for Codable types
- Default value registration with atomic guarantees
- Thread-safe operations with Swift 6 concurrency support
- `@MainActor` compatibility for SwiftUI integration
- Mock implementation (`SettingsMock`) for testing
- Comprehensive test suite with 92 tests
- Complete API documentation with examples

### Performance
- Lazy default value encoding (only on first registration)
- Atomic registration prevents redundant UserDefaults updates
- Efficient storage using property list native types when possible

### Documentation
- Comprehensive README with quick start guide
- Usage examples for common patterns
- SwiftUI integration examples
- Reactive programming patterns
- Apache 2.0 License

[0.1.0]: https://github.com/couchdeveloper/Settings/releases/tag/v0.1.0
