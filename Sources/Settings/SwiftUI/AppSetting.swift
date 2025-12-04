#if canImport(SwiftUI)
import SwiftUI
import Combine

/// A default container for UserDefaults that uses the standard store with no prefix.
///
/// This container provides a convenient way to define app-wide settings without
/// needing to create a custom container. Extend this type with `@Setting`
/// properties to make them available throughout your app:
///
/// ```swift
/// extension AppSettingValues {
///     @Setting var username: String = "guest"
///     @Setting var theme: String = "light"
///     @Setting var notificationsEnabled: Bool = true
/// }
/// ```
///
/// These settings can then be used in SwiftUI views with keypath syntax:
///
/// ```swift
/// struct SettingsView: View {
///     @AppSetting(\.username) var username
///     @AppSetting(\.theme) var theme
///
///     var body: some View {
///         Form {
///             TextField("Username", text: $username)
///             Picker("Theme", selection: $theme) {
///                 Text("Light").tag("light")
///                 Text("Dark").tag("dark")
///             }
///         }
///     }
/// }
/// ```
public struct AppSettingValues: __Settings_Container {
    public static var store: UserDefaults {
        UserDefaults.standard
    }
}

/// A SwiftUI property wrapper that provides a binding to a single UserDefault value.
///
/// Use this property wrapper in SwiftUI views to create bindings to individual
/// UserDefault properties, with automatic view updates when the value changes:
///
/// ```swift
/// @Settings(prefix: "com_example_app_")
/// struct AppSettings {
///     @Setting static var username: String = "guest"
///     @Setting static var isDarkMode: Bool = false
/// }
///
/// struct SettingsView: View {
///     @AppSetting(AppSettings.$username) var username
///     @AppSetting(AppSettings.$isDarkMode) var darkMode
///
///     var body: some View {
///         Form {
///             TextField("Username", text: $username)
///             Toggle("Dark Mode", isOn: $darkMode)
///         }
///     }
/// }
/// ```
///
/// Additionally, the Settings library provides `AppSettingValues`, a default container that simplifies
/// setting up UserDefaults-backed settings. You can declare settings in an extension and use them via
/// key paths:
///
/// ```swift
/// extension AppSettingValues {
///     @Setting var username: String = "guest"
///     @Setting var isDarkMode: Bool = false
/// }
///
/// struct SettingsView: View {
///     @AppSetting(\.$username) var username
///     @AppSetting(\.$isDarkMode) var isDarkMode
///
///     var body: some View {
///         Form {
///             TextField("Username", text: $username)
///             Toggle("Dark Mode", isOn: $isDarkMode)
///         }
///     }
/// }
/// ```
///
/// See the documentation on `AppSettingValues` for additional details.
///
/// The property wrapper observes the specific UserDefaults key and triggers
/// view updates when the value changes, whether from the current view or elsewhere
/// in the app.
@propertyWrapper
public struct AppSetting<Attribute: __Attribute>: DynamicProperty
where Attribute.Value: Sendable, Attribute.Container.Store: UserDefaults {

    @State private var value: Attribute.Value
    @State private var cancellable: AnyCancellable?

    /// The current UserDefaults value.
    public var wrappedValue: Attribute.Value {
        get { value }
        nonmutating set {
            value = newValue
            Attribute.write(value: newValue)
        }
    }

    /// Provides a binding to the UserDefaults value.
    public var projectedValue: Binding<Attribute.Value> {
        $value
    }

    /// Creates a new AppSetting property wrapper for the specified attribute.
    public init(_ attribute: Attribute.Type) {
        self._value = State(initialValue: Attribute.read())
    }

    /// Creates a new AppSetting property wrapper from a UserDefaults projected value.
    ///
    /// This allows cleaner syntax for custom containers:
    /// ```swift
    /// @MyAppSetting(MyAppSettingValues.$username) var username
    /// ```
    public init(_ proxy: __AttributeProxy<Attribute>) {
        self._value = State(initialValue: Attribute.read())
    }

    /// Creates a new AppSetting property wrapper using a key path to an
    /// `AppSettingValues` property.
    ///
    /// This provides the cleanest syntax for the default container:
    /// ```swift
    /// extension AppSettingValues {
    ///     @Setting var username: String = "guest"
    /// }
    ///
    /// struct MyView: View {
    ///     @AppSetting(\.$username) var username
    /// }
    /// ```
    ///
    /// - Parameter keyPath: A key path to a property on the default `AppSettingValues` container.
    public init(
        _ keyPath: KeyPath<AppSettingValues, __AttributeProxy<Attribute>>
    ) where Attribute.Container == AppSettingValues {
        self._value = State(initialValue: Attribute.read())
    }

    /// Creates a new AppSetting property wrapper using a key path to a property
    /// on a custom settings container.
    ///
    /// Use this to reference settings defined on a non-default container:
    /// ```swift
    /// extension MyAppSettingValues {
    ///     @Setting var username: String = "guest"
    /// }
    ///
    /// struct MyView: View {
    ///     @AppSetting(\AppSettingValues.$username) var username
    /// }
    /// ```
    ///
    /// - Parameter keyPath: A key path to a property on the custom `Attribute.Container`.
    public init(
        _ keyPath: KeyPath<Attribute.Container, __AttributeProxy<Attribute>>
    ) {
        self._value = State(initialValue: Attribute.read())
    }

    /// Called by SwiftUI to set up the publisher subscription.
    public mutating func update() {
        if cancellable == nil {
            cancellable = Attribute.publisher
                .catch { _ in Just(Attribute.read()) }
                .receive(on: DispatchQueue.main)
                .sink { [wrappedValue = $value] newValue in
                    wrappedValue.wrappedValue = newValue
                }
        }
    }
}

#endif
