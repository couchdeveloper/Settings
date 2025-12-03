import Foundation

extension Foundation.UserDefaults: UserDefaultsStore {

    public func observer(
        forKey key: String,
        update: @escaping @Sendable (_ old: Any?, _ new: Any?) -> Void
    ) -> some Cancellable {
        UserDefaultsObserver(
            store: self,
            key: key,
            options: [.initial, .old, .new],
            callback: { _, old, new in
                update(old, new)
            }
        )
    }

}
