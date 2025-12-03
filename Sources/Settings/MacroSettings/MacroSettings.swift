/// Macro: `@Settings`
///
/// A type macro that generates a strongly-typed proxy around `Foundation.UserDefaults`.
/// Use it to declare a container whose members describe a set of keys in a defaults store.
///
/// ## Supported Declarations
/// - Attach to: `enum`, ` struct`, `class`, or `actor`.
/// - Placement: top-level, nested types, or within functions.
///
/// ## Attributes
/// - `prefix: String?` — Optional key prefix that is applied to all generated keys.
/// - `suiteName: String?` — Optional suite name used to create a `UserDefaults` instance via `UserDefaults(suiteName:)`.
///   If `nil`, the standard defaults are used.
///
/// ## Members
/// - Within the container, declare properties using the `@Setting` member macro to bind keys and default values.
/// - You can also add `@Setting` members from extensions of the same container.
///
/// ## Example
/// A simple container with one `@Setting` property. This example also demonstrates
/// the `prefix` and `suiteName` parameters on `@Settings`.
///
/// ```swift
/// import Foundation
///
/// @Settings(
///     prefix: "app_",
///     suiteName: "group.com.example.shared"
/// ) struct AppSettings {
///     // Stores a boolean under key: "app_hasSeenOnboarding"
///     // in the specified suite.
///     @Setting(key: "hasSeenOnboarding", default: false)
///     static var hasSeenOnboarding: Bool
/// }
///
/// // Usage
/// // Read
/// let seen = AppSettings.hasSeenOnboarding
///
/// // Write
/// AppSettings.hasSeenOnboarding = true
/// ```
///
/// ## Observation
/// Integrate with the Observation framework using instance properties:
///
/// ```swift
/// import Observation
///
/// @Observable
/// final class ViewModel {
///     @Settings struct Settings {
///         @Setting var hasSeenOnboarding = false
///     }
///     
///     var settings = Settings()
/// }
///
/// // SwiftUI views automatically update when settings.hasSeenOnboarding changes
/// ```
@attached(member)
@attached(
    extension,
    conformances: __Settings_Container,
    names: named(prefix),
    named(suiteName)
)
public macro Settings(
    prefix: String? = nil,
    suiteName: String? = nil
) = #externalMacro(
    module: "SettingsMacros",
    type: "SettingsMacro"
)
