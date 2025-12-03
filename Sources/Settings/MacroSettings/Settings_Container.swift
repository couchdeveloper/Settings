import Foundation

public protocol __Settings_Container {
    associatedtype Store: UserDefaultsStore
    associatedtype Observer: Cancellable

    static var store: Store { get }
    static var prefix: String { get }

    // MARK: - UserDefaults Operations
    static func bool(forKey key: String) -> Bool
    static func integer(forKey key: String) -> Int
    static func double(forKey key: String) -> Double
    static func float(forKey key: String) -> Float
    static func string(forKey key: String) -> String?
    static func url(forKey key: String) -> URL?
    static func data(forKey key: String) -> Data?
    static func object(forKey key: String) -> Any?
    static func array(forKey key: String) -> [Any]?
    static func dictionary(forKey key: String) -> [String: Any]?

    static func set(_ value: Bool, forKey key: String)
    static func set(_ value: Int, forKey key: String)
    static func set(_ value: Double, forKey key: String)
    static func set(_ value: Float, forKey key: String)
    static func set(_ value: String, forKey key: String)
    static func set(_ value: URL, forKey key: String)
    static func set(_ value: Data, forKey key: String)
    static func set(_ value: Any, forKey key: String)

    static func removeObject(forKey key: String)

    static func registerDefault(key: String, defaultValue: Any)

    static func observer(
        forKey: String,
        update: @escaping @Sendable (Any?, Any?) -> Void
    ) -> Observer

}

extension __Settings_Container {

    /// Accesses the UserDefault value associated with a custom Attribute.
    ///
    /// Create a custom UserDefault value by declaring a new property
    /// in an extension to the a user defaults container and applying
    /// the ``UserDefault()`` macro to the variable declaration:
    ///
    ///     extension UserDefaultsContainer {
    ///         @Setting var myCustomValue: String = "Default value"
    ///     }
    ///
    public static subscript<A>(attribute: A.Type) -> A.Value
    where A: __Attribute, A.Container == Self {
        get {
            attribute.read()
        }
        set {
            attribute.write(value: newValue)
        }
    }
    
}

extension __Settings_Container {
    public static var prefix: String { "" }
    public static var store: Foundation.UserDefaults { .standard }
}

// MARK: - Default UserDefaults Operations

extension __Settings_Container {

    public static func bool(forKey key: String) -> Bool {
        return store.bool(forKey: key)
    }

    public static func integer(forKey key: String) -> Int {
        return store.integer(forKey: key)
    }

    public static func double(forKey key: String) -> Double {
        return store.double(forKey: key)
    }

    public static func float(forKey key: String) -> Float {
        return store.float(forKey: key)
    }

    public static func string(forKey key: String) -> String? {
        return store.string(forKey: key)
    }

    public static func url(forKey key: String) -> URL? {
        return store.url(forKey: key)
    }

    public static func data(forKey key: String) -> Data? {
        return store.data(forKey: key)
    }

    public static func object(forKey key: String) -> Any? {
        return store.object(forKey: key)
    }

    public static func array(forKey key: String) -> [Any]? {
        return store.array(forKey: key)
    }

    public static func dictionary(forKey key: String) -> [String: Any]? {
        return store.dictionary(forKey: key)
    }

    public static func set(_ value: Bool, forKey key: String) {
        store.set(value, forKey: key)
    }

    public static func set(_ value: Int, forKey key: String) {
        store.set(value, forKey: key)
    }

    public static func set(_ value: Double, forKey key: String) {
        store.set(value, forKey: key)
    }

    public static func set(_ value: Float, forKey key: String) {
        store.set(value, forKey: key)
    }

    public static func set(_ value: String, forKey key: String) {
        store.set(value, forKey: key)
    }

    public static func set(_ value: URL, forKey key: String) {
        store.set(value, forKey: key)
    }

    public static func set(_ value: Data, forKey key: String) {
        store.set(value, forKey: key)
    }

    public static func set(_ value: Any, forKey key: String) {
        store.set(value, forKey: key)
    }

    public static func removeObject(forKey key: String) {
        store.removeObject(forKey: key)
    }
}

extension __Settings_Container {
    public static func registerDefault(key: String, defaultValue: Any) {
        Self.store.register(defaults: [key: defaultValue])
    }
}

extension __Settings_Container {
    public static func observer(
        forKey key: String,
        update: @escaping @Sendable (Any?, Any?) -> Void
    ) -> some Cancellable {
        self.store.observer(forKey: key, update: update)
    }
}
