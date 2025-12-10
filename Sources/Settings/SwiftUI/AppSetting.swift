#if canImport(SwiftUI)
    import SwiftUI
    import Combine
    import os

    /// A default container for UserDefaults that uses a configurable store.
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
    ///
    /// ## Store Configuration
    ///
    /// By default, `AppSettingValues` uses `UserDefaults.standard`. You can configure
    /// a different store at runtime:
    ///
    /// ```swift
    /// // Use a mock store for testing
    /// AppSettingValues.configureStore(UserDefaultsStoreMock())
    ///
    /// // Reset to standard
    /// AppSettingValues.resetStore()
    /// ```
    public struct AppSettingValues: __Settings_Container {
        struct Config {
            var store: any UserDefaultsStore = UserDefaults.standard
            var prefix: String? = nil
        }

        private static let _config = OSAllocatedUnfairLock<Config>(
            initialState: Config()
        )

        public internal(set) static var store: any UserDefaultsStore {
            get {
                _config.withLock { config in
                    config.store
                }
            }
            set {
                _config.withLock { config in
                    config.store = newValue
                }
            }
        }

        public static var prefix: String {
            get {
                _config.withLock { config in
                    if let prefix = config.prefix {
                        return prefix
                    }
                    guard let identifier = Bundle.main.bundleIdentifier else {
                        return "app_"
                    }
                    return identifier.replacing(".", with: "_") + "_"
                }
            }
            set {
                _config.withLock { config in
                    config.prefix = newValue.replacing(".", with: "_")
                }
            }
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
    /// ## Store Configuration
    ///
    /// By default, `AppSetting` uses `UserDefaults.standard`. You can configure
    /// a different store at runtime using SwiftUI environment value `userDefaultsStore`:
    ///
    /// ```swift
    /// @main
    /// struct ViewAppApp: App {
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             MainView()
    ///             .environment(
    ///                 \.userDefaultsStore,
    ///                 UserDefaultsStoreMock()
    ///             )
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
    @MainActor
    @propertyWrapper
    public struct AppSetting<Attribute: __Attribute>: @MainActor DynamicProperty
    where Attribute.Value: Sendable {

        @State private var value: Attribute.Value
        @State private var observer: Observer = Observer()
        @Environment(\.userDefaultsStore) private var environmentStore

        /// The current UserDefaults value.
        public var wrappedValue: Attribute.Value {
            get {
                value
            }
            nonmutating set {
                Attribute.write(value: newValue)
            }
        }

        /// Provides a binding to the UserDefaults value.
        public var projectedValue: Binding<Attribute.Value> {
            Binding(
                get: {
                    wrappedValue
                },
                set: { value in
                    wrappedValue = value
                }
            )
        }

        /// Creates a new AppSetting property wrapper for the specified attribute.
        public init(_ attribute: Attribute.Type) {
            self._value = .init(initialValue: Attribute.defaultValue)
        }

        /// Creates a new AppSetting property wrapper from a UserDefaults projected value.
        ///
        /// This allows cleaner syntax for custom containers:
        /// ```swift
        /// @MyAppSetting(MyAppSettingValues.$username) var username
        /// ```
        public init(_ proxy: __AttributeProxy<Attribute>) {
            self._value = .init(initialValue: Attribute.defaultValue)
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
            self._value = .init(initialValue: Attribute.defaultValue)
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
            self._value = .init(initialValue: Attribute.defaultValue)
        }

        /// Called by SwiftUI to set up the publisher subscription.
        public mutating func update() {
            if !(AppSettingValues.store === environmentStore) {
                AppSettingValues.store = environmentStore
            }
            // print("*** SwiftUI update: \(AppSettingValues.store.dictionaryRepresentation())")
            observer.observe(binding: $value)
        }
    }

    extension AppSetting {

        @MainActor
        final class Observer {
            var cancellable: AnyCancellable? = nil
            weak var usersDefaultsStore: (any UserDefaultsStore)?

            init() {}

            func observe(binding: Binding<Attribute.Value>) {
                // When the store of the attribute has changed, we need
                // to cancel the subscription and create a new one:
                if !(usersDefaultsStore === Attribute.Container.store) {
                    cancel()
                }
                if cancellable == nil {
                    usersDefaultsStore = Attribute.Container.store
                    cancellable = Attribute.publisher
                        .catch { _ in Just(Attribute.read()) }
                        .receive(on: DispatchQueue.main)
                        .sink { newValue in
                            print("Observer: \(Attribute.self) = \(newValue)")
                            binding.wrappedValue = newValue
                        }
                }
            }

            func cancel() {
                cancellable = nil
            }
        }

    }
#endif
