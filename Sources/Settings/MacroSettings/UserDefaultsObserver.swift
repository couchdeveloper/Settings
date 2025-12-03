import Foundation
import Synchronization

final class UserDefaultsObserver: NSObject, Cancellable, @unchecked Sendable {

    typealias StoreChangeCallback =
        @Sendable (_ keyPath: String?, _ oldValue: Any?, _ newValue: Any?) ->
        Void

    var store: Foundation.UserDefaults?
    let key: String
    let callback: StoreChangeCallback

    init(
        store: Foundation.UserDefaults,
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
