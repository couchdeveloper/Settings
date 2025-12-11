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
///   If `nil`, `UserDefaults.standard` is used.
///
/// ## Members
/// - Within the container, declare properties using the `@Setting` member macro to bind keys and default values.
/// - You can also add `@Setting` members from extensions of the same container.
///
/// ## Example
/// A UserDefaults container with one `@Setting` property. The UserDefaults container defines
/// a `prefix`parameter - which will be prepended to all keys, and a `suiteName` parameter
/// which defines the suite name for the custom UserDefaults instance.
///  on `@Settings`.
///
/// ```swift
/// import Foundation
/// import Settings
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
/// ```
///  >Note: A UserDefaults container using the macro `@Settings` can be declared at top level of any
///  file. For better ergonomics, declare setting values as *static* members. Make the container public so
///  that it is visible in other modules.
///
/// ## Usage
/// ```swift
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
/// ```
/// SwiftUI views automatically update when settings.hasSeenOnboarding changes
///
///  >Note: A UserDefaults container using the macro `@Settings` can be declared within classes or
///  structs.

@attached(
    member,
    names: named(Config),
    named(state),
    named(store),
    named(prefix)
)
@attached(
    extension,
    conformances: __Settings_Container
)
public macro Settings(
    prefix: String? = nil,
    suiteName: String? = nil
) =
    #externalMacro(
        module: "SettingsMacros",
        type: "SettingsMacro"
    )
