
<p align="center">
  <img src="Resources/settings-icon.png" alt="Settings Icon" width="200"/>
</p>

# Settings - Type-Safe UserDefaults for Swift

<p align="center">
  <a href="https://github.com/couchdeveloper/Settings">
    <img src="https://img.shields.io/badge/⚙️-Settings-blue?color=4A90E2" alt="Settings Framework"/>
  </a>
  <a href="https://swift.org">
    <img src="https://img.shields.io/badge/Swift-6.1-orange.svg" alt="Swift 6.1"/>
  </a>
  <a href="https://swift.org">
    <img src="https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-brightgreen.svg" alt="Platforms"/>
  </a>
  <a href="https://developer.apple.com/ios/">
    <img src="https://img.shields.io/badge/iOS-17.0%2B-blue.svg" alt="iOS 17.0+"/>
  </a>
  <a href="https://developer.apple.com/macos/">
    <img src="https://img.shields.io/badge/macOS-15.0%2B-blue.svg" alt="macOS 15.0+"/>
  </a>
  <a href="https://github.com/apple/swift-package-manager">
    <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="SPM"/>
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License"/>
  </a>
</p>

Type-safe, macro-powered Swift package for `UserDefaults`.

## Features

- **Type-safe** — Compile-time type checking with generated keys
- **No boilerplate** — `@Settings` and `@Setting` generate accessors and metadata
- **UserDefaults-compatible** — Integrates with existing suites without migration
- **Codable-first** — Encode any `Codable` type via JSON or property list
- **Native storage** — Stores property list–compatible types directly (String, Int, Bool, Date, Data, URL, Array, Dictionary)
- **Observable** — Built-in `Combine` publishers and `AsyncSequence` streams
- **Customizable** — Namespaced keys and pluggable encoders/decoders

## SwiftUI Integration

```swift
import Settings
import SwiftUI

// Special mockable Settings container.
// Uses UserDefaults.standard per default.
extension AppSettingValues {
    @Setting public var score: Int = 0
}

struct AppSettingsView: View {
    @AppSetting(\.$score) var score

    var body: some View {
        Form {
            TextField("Enter your score", value: $score, format: .number)
                .textFieldStyle(.roundedBorder)
                .padding()

            Text("Your score was \(score).")
        }
    }
}

#if DEBUG
import SettingsMock

#Preview {
    AppSettingsView()
        .environment(\.userDefaultsStore, UserDefaultsStoreMock.standard)
}
#endif
```

## Set a global key prefix:

```swift 
@main
struct MyApp: App {
    init() {
        AppSettingValues.prefix = "myapp_"
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
```

> **Note:** When the prefix is not customized, Settings library will use the bundle identifier from the main bundle to derive a unique prefix for every key.


## Custom Settings Container

```swift
import Settings

@Settings(prefix: "app_") // keys prefixed with "app_"
struct AppSettings {
    @Setting static var username: String = "Guest"
    @Setting(name: "colorScheme") static var theme: String = "light" // key = "colorScheme"
    @Setting static var apiKey: String? // optional: no default
}

AppSettings.username = "Alice"
print(AppSettings.theme) // "light"
```

## Projected Value ($propertyName)

Access metadata and observe changes:

```swift
// Key
print(AppSettings.$username.key) // "app_username"
print(AppSettings.$theme.key)    // "colorScheme"

// Reset
AppSettings.$theme.reset()

// Observe (Combine)
AppSettings.$theme.publisher.sink { print("Theme:", $0) }

// Observe (AsyncSequence)
for try await theme in AppSettings.$theme.stream {
    print("Theme:", theme)
}
```

## Codable

```swift
struct UserProfile: Codable, Equatable {
    let name: String
    let age: Int
}

@Settings(prefix: "app_")
struct Settings {
    @Setting(encoding: .json)
    static var profile: UserProfile = .init(name: "Guest", age: 0)
}

Settings.profile = .init(name: "Alice", age: 30)
```

## Optionals

```swift
@Settings(prefix: "app_")
struct Settings {
    @Setting static var apiKey: String?  // no default value!
}

Settings.apiKey = "secret123"
Settings.apiKey = nil // removes key from UserDefaults
```

## Nested Containers

```swift
extension AppSettings { enum UserSettings {} }

extension AppSettings.UserSettings {
    @Setting static var email: String?
}

print(AppSettings.UserSettings.$email.key) // "app_UserSettings::email"
AppSettings.UserSettings.email = "alice@example.com"
```

## Concurrency

Use explicit isolation if accessed across actors.

```swift
@Settings(prefix: "app_")
struct Settings {
    @MainActor @Setting static var theme: String = "light"
}
```

## Requirements

- Swift 6.2
- macOS 10.15+ / iOS 17.0+ / tvOS 17.0+ / watchOS 10.0+

## Installation

### Swift Package Manager

Add Settings to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/couchdeveloper/Settings.git", from: "0.4.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/couchdeveloper/Settings.git`
3. Select version: 0.4.0 or later


## Advanced

```swift
// Suite (App Group)
@Settings(prefix: "shared_", suiteName: "group.com.myapp")
struct SharedSettings {
    @Setting static var syncEnabled: Bool = true
}

// Custom key
@Setting(name: "custom_key")
static var value: Int = 42

// Custom encoders/decoders
@Setting(encoder: JSONEncoder(), decoder: JSONDecoder())
static var customProfile: UserProfile = .init(name: "Custom", age: 0)

// Key-path observation
struct User: Codable, Equatable { var name: String; var age: Int }

@Settings(prefix: "app_")
struct Settings {
    @Setting(encoding: .json)
    static var user: User = .init(name: "Guest", age: 0)
}

for try await name in Settings.$user.stream(for: \.name) {
    print("Name:", name)
}
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Apache License (v2.0) - See [LICENSE](LICENSE) file for details

