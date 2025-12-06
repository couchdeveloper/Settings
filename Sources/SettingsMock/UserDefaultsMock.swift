import Foundation
import os
import Settings

public final class UserDefaultsStoreMock: NSObject, UserDefaultsStore, Sendable {
    
    public static let standard: UserDefaultsStoreMock = .init(store: [:])
    
    struct State: @unchecked Sendable {
        init(store: sending [String: Any] = [:]) {
            self.values = store
            self.defaults = [:]
        }
        var values: [String: Any]
        var defaults: [String: Any]
    }
    
    public init(store: [String: Any]) {
        var sanitized: [String: Any] = [:]
        for (k, v) in store {
            if PropertyListSerialization.propertyList(v, isValidFor: .binary),
              let data = try? PropertyListSerialization.data(fromPropertyList: v, format: .binary, options: 0),
              let copy = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) {
                sanitized[k] = copy
            }
        }
        state = OSAllocatedUnfairLock(initialState: State(store: sanitized))
        super.init()
    }
    
    override public init() {
        state = OSAllocatedUnfairLock(initialState: State())
        super.init()
    }
    
    let state: OSAllocatedUnfairLock<State>
    
    
    public func reset() {
        state.withLock { state in
            state.values.removeAll()
        }
    }
    
    public func clear() {
        state.withLock { state in
            state.values.removeAll()
            state.defaults.removeAll()
        }
    }
    
    public func unregisterDefaults() {
        state.withLock { state in
            state.defaults.removeAll()
        }
    }
    
    private func plistDeepCopy(_ value: Any) -> Any? {
        guard PropertyListSerialization.propertyList(value, isValidFor: .binary) else { return nil }
        guard let data = try? PropertyListSerialization.data(fromPropertyList: value, format: .binary, options: 0) else { return nil }
        return try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    }
    
    private func isEqualPlist(_ lhs: Any?, _ rhs: Any?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (l?, r?):
            if let lo = l as? NSObject, let ro = r as? NSObject {
                return lo.isEqual(ro)
            }
            return false
        default:
            return false
        }
    }
    
    private func readEffectiveValue(forKey key: String) -> Any? {
        state.withLockUnchecked { state in
            state.values[key] ?? state.defaults[key]
        }
    }
    
    private func number(from any: Any) -> NSNumber? {
        if let n = any as? NSNumber { return n }
        if let i = any as? Int { return NSNumber(value: i) }
        if let d = any as? Double { return NSNumber(value: d) }
        if let f = any as? Float { return NSNumber(value: f) }
        if let b = any as? Bool { return NSNumber(value: b) }
        return nil
    }
    
    public func object(forKey key: String) -> Any? {
        readEffectiveValue(forKey: key)
    }
    
    public func set(_ value: Any?, forKey key: String) {
        if let value {
            // Only accept property-list-serializable values; mimic UserDefaults by ignoring unsupported values.
            guard let stored = plistDeepCopy(value) else {
                return
            }
            var oldEffective: Any?
            state.withLockUnchecked { state in
                oldEffective = state.values[key] ?? state.defaults[key]
            }
            let shouldNotify = !isEqualPlist(oldEffective, stored)
            if shouldNotify { willChangeValue(forKey: key) }
            state.withLockUnchecked { state in
                state.values[key] = stored
            }
            if shouldNotify { didChangeValue(forKey: key) }
        } else {
            // Removing a value restores the effective value to the default for the key (if any).
            var oldEffective: Any?
            var newEffective: Any?
            state.withLockUnchecked { state in
                oldEffective = state.values[key] ?? state.defaults[key]
                newEffective = state.defaults[key]
            }
            let shouldNotify = !isEqualPlist(oldEffective, newEffective)
            if shouldNotify { willChangeValue(forKey: key) }
            state.withLock { state in
                _ = state.values.removeValue(forKey: key)
            }
            if shouldNotify { didChangeValue(forKey: key) }
        }
    }
    
    public func removeObject(forKey key: String) {
        set(nil, forKey: key)
    }
    
    public func string(forKey key: String) -> String? {
        readEffectiveValue(forKey: key) as? String
    }
    
    public func array(forKey key: String) -> [Any]? {
        readEffectiveValue(forKey: key) as? [Any]
    }
    
    public func dictionary(forKey key: String) -> [String : Any]? {
        readEffectiveValue(forKey: key) as? [String : Any]
    }
    
    public func data(forKey key: String) -> Data? {
        readEffectiveValue(forKey: key) as? Data
    }
    
    public func stringArray(forKey key: String) -> [String]? {
        readEffectiveValue(forKey: key) as? [String]
    }
    
    public func integer(forKey key: String) -> Int {
        guard let v = readEffectiveValue(forKey: key) else { return 0 }
        if let i = v as? Int { return i }
        if let n = number(from: v) { return n.intValue }
        return 0
    }
    
    public func float(forKey key: String) -> Float {
        guard let v = readEffectiveValue(forKey: key) else { return 0 }
        if let f = v as? Float { return f }
        if let n = number(from: v) { return n.floatValue }
        return 0
    }
    
    public func double(forKey key: String) -> Double {
        guard let v = readEffectiveValue(forKey: key) else { return 0 }
        if let d = v as? Double { return d }
        if let n = number(from: v) { return n.doubleValue }
        return 0
    }
    
    public func bool(forKey key: String) -> Bool {
        guard let v = readEffectiveValue(forKey: key) else { return false }
        if let b = v as? Bool { return b }
        if let n = number(from: v) { return n.boolValue }
        return false
    }
    
    public func url(forKey key: String) -> URL? {
        readEffectiveValue(forKey: key) as? URL
    }
    
    public func set(_ value: Int, forKey key: String) { set(value as Any, forKey: key) }
    public func set(_ value: Float, forKey key: String) { set(value as Any, forKey: key) }
    public func set(_ value: Double, forKey key: String) { set(value as Any, forKey: key) }
    public func set(_ value: Bool, forKey key: String) { set(value as Any, forKey: key) }
    public func set(_ url: URL?, forKey key: String) { set(url as Any?, forKey: key) }
    
    public func register(defaults newDefaults: [String : Any]) {
        for (key, newDefault) in newDefaults {
            // Only accept property-list-serializable defaults
            guard let copy = plistDeepCopy(newDefault) else { continue }

            var hasUserValue = false
            var oldEffective: Any?
            var newEffective: Any?
            state.withLockUnchecked { state in
                hasUserValue = state.values[key] != nil
                oldEffective = state.values[key] ?? state.defaults[key]
                newEffective = hasUserValue ? state.values[key] : copy
            }

            let shouldNotify = !hasUserValue && !isEqualPlist(oldEffective, newEffective)
            if shouldNotify { willChangeValue(forKey: key) }
            state.withLockUnchecked { state in
                state.defaults[key] = copy
            }
            if shouldNotify { didChangeValue(forKey: key) }
        }
    }
    
    public override func value(forKey key: String) -> Any? {
        object(forKey: key)
    }
    
    public override func setValue(_ value: Any?, forKey key: String) {
        set(value, forKey: key)
    }
    
    public func dictionaryRepresentation() -> [String : Any] {
        state.withLockUnchecked { state in
            var values = state.values
            values.merge(state.defaults, uniquingKeysWith: { lhs, rhs in lhs })
            return values
        }
    }
}

extension UserDefaultsStoreMock {

    public func observer(
        forKey key: String,
        update: @escaping @Sendable (_ old: Any?, _ new: Any?) -> Void
    ) -> some Cancellable {
        UserDefaultsStoreMockObserver(
            store: self,
            key: key,
            options: [.initial, .old, .new],
            callback: { _, old, new in
                update(old, new)
            }
        )
    }

}


final class UserDefaultsStoreMockObserver: NSObject, Cancellable, @unchecked Sendable {

    typealias StoreChangeCallback =
        @Sendable (_ keyPath: String?, _ oldValue: Any?, _ newValue: Any?) ->
        Void

    var store: UserDefaultsStoreMock?
    let key: String
    let callback: StoreChangeCallback

    init(
        store: UserDefaultsStoreMock,
        key: String,
        options: NSKeyValueObservingOptions = [.initial, .old, .new],
        callback: @escaping StoreChangeCallback
    ) {
        self.store = store
        self.key = key
        self.callback = callback

        super.init()

        // Registers `self` to receive KVO notifications sent from the store.
        // Note that neither `store` nor `self` will be retained in the
        // following method call.
        store.addObserver(
            self,
            forKeyPath: key,
            options: options,
            context: nil
        )
    }

    deinit {
        cancel()
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        assert(keyPath == key, "KVO notification received for unexpected keyPath: \(keyPath ?? "nil"), expected: \(key)")
        callback(keyPath, change?[.oldKey], change?[.newKey])
    }

    func cancel() {
        if let store {
            store.removeObserver(self, forKeyPath: key)
            self.store = nil
        }
    }
}

