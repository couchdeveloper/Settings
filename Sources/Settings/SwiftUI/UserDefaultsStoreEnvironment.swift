#if canImport(SwiftUI)
import SwiftUI
import Foundation

/// Environment key for providing a `UserDefaultsStore` to SwiftUI views.
///
/// This allows you to inject a custom store (like `UserDefaultsStoreMock`) for testing
/// and previews, while using the real `UserDefaults.standard` in production.
struct UserDefaultsStoreKey: EnvironmentKey {
    static var defaultValue: any UserDefaultsStore { UserDefaults.standard }
}

extension EnvironmentValues {
    /// The `UserDefaultsStore` used by `@AppSetting` property wrappers in the current view hierarchy.
    ///
    /// By default, this is `UserDefaults.standard`. You can override it for testing or previews:
    ///
    /// ```swift
    /// struct ContentView_Previews: PreviewProvider {
    ///     static var previews: some View {
    ///         ContentView()
    ///             .userDefaultsStore(UserDefaultsStoreMock())
    ///     }
    /// }
    /// ```
    @Entry public var userDefaultsStore: any UserDefaultsStore = UserDefaults.standard
}

extension View {
    /// Sets the `UserDefaultsStore` for this view and its children.
    ///
    /// Use this modifier to provide a mock store for testing or previews:
    ///
    /// ```swift
    /// struct SettingsView_Previews: PreviewProvider {
    ///     static var previews: some View {
    ///         let mockStore = UserDefaultsStoreMock()
    ///         mockStore.set("TestUser", forKey: "username")
    ///         mockStore.set(true, forKey: "darkMode")
    ///
    ///         return SettingsView()
    ///             .userDefaultsStore(mockStore)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter store: The `UserDefaultsStore` to use for `@AppSetting` properties.
    /// - Returns: A view that uses the specified store.
    public func userDefaultsStore(_ store: some UserDefaultsStore) -> some View {
        environment(\.userDefaultsStore, store)
    }
}

#endif
