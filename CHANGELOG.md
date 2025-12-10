# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2025-12-10

### Changed
- **BREAKING**: Added `AnyObject` constraint to `UserDefaultsStore` protocol for identity comparison

### Fixed
- Fixed observer lifecycle: properly cancel and recreate subscriptions when store changes
- Ensured `AppSettingValues.prefix` is KVO-compliant by automatically replacing dots with underscores

### Improved
- Refactored `UserDefaultsStoreMock` helper methods to be static for better encapsulation

## [0.3.1] - 2025-12-09

### Added
- Configurable key prefix for `AppSettingValues` with automatic bundle identifier fallback
- `AppSettingValues.prefix` property for customizing global key prefix at runtime

## [0.3.0] - 2025-12-08

### Changed
- **BREAKING**: Modified `__Settings_Container` protocol to use `any UserDefaultsStore` instead of associated type `Store`
- **BREAKING**: Changed observer return type from associated type `Observer` to `any Cancellable`
- Updated `AppSettingValues` to use `OSAllocatedUnfairLock` for thread-safe store access without actor isolation
- Removed `@MainActor` isolation from `AppSettingValues` to satisfy Swift 6 Sendable requirements

### Added
- Support for SwiftUI environment-based store injection in previews
- Thread-safe dynamic store switching for all custom containers

### Migration Guide
Custom containers need to update from:
```swift
struct MyContainer: __Settings_Container {
    static var store: UserDefaults { .standard }
}
```
To:
```swift
struct MyContainer: __Settings_Container {
    static var store: any UserDefaultsStore { UserDefaults.standard }
}
```

## [0.2.0] - 2025-12-07
- Add UserDefaultsStoreMock and SwiftUI environment-based store injection

## [0.1.3] - 2025-12-06

### Fixed
- Added public access modifiers to macro-generated attribute enum members, fixing compilation errors when using `@Setting` on public properties in library modules

## [0.1.2] - 2025-12-04

### Added
- Comprehensive SwiftUI test suite for `AppSetting` property wrapper
- Publisher tests verifying reactive UserDefaults observation

### Fixed
- `AppSetting` cancellable property now uses `@State` wrapper to prevent subscription loss across view updates

## [0.1.1] - 2025-12-04

### Fixed
- Fixed Package.swift to use GitHub URL for swift-syntax dependency instead of local path

### Changed
- Updated Swift tools version from 6.1 to 6.2
- Improved README formatting and layout

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
