import Foundation
import Testing

// This is ugly, but UserDefaults is documented to be thread-safe, so this
// should be OK.
extension UserDefaults: @retroactive @unchecked Sendable {}

extension UserDefaults {
    func observeKey<Value: Sendable>(_ key: String, valueType _: Value.Type)
        -> AsyncStream<Value?>
    {
        let (stream, continuation) = AsyncStream.makeStream(of: Value?.self)
        let observer = KVOObserver { newValue in
            continuation.yield(newValue)
        }
        continuation.onTermination = { [weak self] termination in
            #if DEBUG
                print(
                    "UserDefaults.observeKey('\(key)') sequence terminated. Reason: \(termination)"
                )
            #endif
            guard let self else { return }
            // Referencing observer here retains it.
            self.removeObserver(observer, forKeyPath: key)
        }
        self.addObserver(
            observer,
            forKeyPath: key,
            options: [
                .initial,
                .new,
            ],
            context: nil
        )
        return stream
    }
}

private final class KVOObserver<Value: Sendable>: NSObject, Sendable {
    let send: @Sendable (Value?) -> Void

    init(send: @escaping @Sendable (Value?) -> Void) {
        self.send = send
    }

    deinit {
        print("KVOObserver deinit")
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        let newValue = change![.newKey]!
        switch newValue {
        case let typed as Value:
            send(typed)
        case nil as Value?:
            send(nil)
        default:
            assertionFailure(
                "UserDefaults value at keyPath '\(keyPath!)' has unexpected type \(type(of: newValue)), expected \(Value.self)"
            )
        }
    }
}

// MARK: - Usage

struct UserDefaultObserverTest {

    @Test func example() async throws {
        let observationTask = Task<Void, Never> {
            for await value in UserDefaults.standard.observeKey(
                "user",
                valueType: [String: Int].self
            ) {
                print("KVO: \(value?.description ?? "nil")")
            }
        }

        // Give observation task an opportunity to run
        try? await Task.sleep(for: .seconds(0.1))

        // These trigger the for loop in observationTask
        UserDefaults.standard.set(
            ["name": 1, "age": 23] as [String: Int],
            forKey: "user"
        )
        UserDefaults.standard.set(["name": 2] as [String: Int], forKey: "user")
        UserDefaults.standard.set(
            ["name": 3, "age": 42] as [String: Int],
            forKey: "user"
        )
        UserDefaults.standard.removeObject(forKey: "user")

        // Cancel observation
        try? await Task.sleep(for: .seconds(1))
        print("Canceling UserDefaults observation")
        observationTask.cancel()

        // These don't print anything because observationTask has been canceled.
        UserDefaults.standard.set(["name": 4] as [String: Int], forKey: "user")
        UserDefaults.standard.removeObject(forKey: "user")

        try? await Task.sleep(for: .seconds(1))
    }

    @Test func example2() async throws {
        let observationTask = Task<Void, Never> {
            for await value in UserDefaults.standard.observeKey(
                "value",
                valueType: Int.self
            ) {
                print("KVO: \(value?.description ?? "nil")")
            }
        }

        // Give observation task an opportunity to run
        try? await Task.sleep(for: .seconds(0.1))

        // These trigger the for loop in observationTask
        UserDefaults.standard.set(1, forKey: "value")
        UserDefaults.standard.set(2, forKey: "value")
        UserDefaults.standard.set(3, forKey: "value")
        UserDefaults.standard.removeObject(forKey: "value")

        // Cancel observation
        try? await Task.sleep(for: .seconds(1))
        print("Canceling UserDefaults observation")
        observationTask.cancel()

        // These don't print anything because observationTask has been canceled.
        UserDefaults.standard.set(4, forKey: "value")
        UserDefaults.standard.removeObject(forKey: "value")

        try? await Task.sleep(for: .seconds(1))
    }

}
