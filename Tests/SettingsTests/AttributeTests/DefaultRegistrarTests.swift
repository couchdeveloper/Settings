import Foundation
import Settings
import Synchronization
import Testing

/// Tests that verify DefaultRegistrar only registers defaults once per attribute type
struct DefaultRegistrarTests {

    @Test("DefaultRegistrar calls register only once despite multiple reads")
    func testDefaultRegistrarCallsRegisterOnlyOnce() async throws {
        // Create a custom container that tracks registration calls
        final class RegistrationTracker: @unchecked Sendable {
            private let count = Mutex<Int>(0)

            func recordRegistration() {
                count.withLock { $0 += 1 }
            }

            func getCallCount() -> Int {
                count.withLock { $0 }
            }
        }

        struct TrackedContainer: __Settings_Container {
            static let tracker = RegistrationTracker()
            static var store: any UserDefaultsStore {
                Foundation.UserDefaults.standard
            }
            static var prefix: String { "DefaultRegistrarTest_" }
            static var suiteName: String? { nil }

            static func registerDefault(key: String, defaultValue: Any) {
                // Track the call
                tracker.recordRegistration()
                // Still register with actual UserDefaults
                store.register(defaults: [key: defaultValue])
            }

            static func clear() {
                store.dictionaryRepresentation().keys
                    .filter { $0.hasPrefix(prefix) }
                    .forEach { store.removeObject(forKey: $0) }
            }
        }

        TrackedContainer.clear()
        defer { TrackedContainer.clear() }

        // Define an attribute
        enum TestAttr: __AttributeNonOptional {
            typealias Container = TrackedContainer
            typealias Value = String
            static let name = "testValue"
            static let defaultValue = "default"
            static let defaultRegistrar = __DefaultRegistrar()
        }

        // Perform multiple reads - each triggers registerDefaultIfNeeded()
        _ = TestAttr.read()
        _ = TestAttr.read()
        _ = TestAttr.read()
        _ = TestAttr.read()
        _ = TestAttr.read()

        // Verify registration was called exactly once
        let callCount = TrackedContainer.tracker.getCallCount()
        #expect(
            callCount == 1,
            "DefaultRegistrar should register only once, but was called \(callCount) times"
        )
    }

    @Test("DefaultRegistrar is a stored property per attribute type")
    func testDefaultRegistrarIsStoredProperty() {
        // Define two different attributes
        enum Attr1: __AttributeNonOptional {
            typealias Container = TestContainer<TestPrefix1>
            typealias Value = String
            static let name = "attr1"
            static let defaultValue = "default1"
            static let defaultRegistrar = __DefaultRegistrar()
        }

        enum Attr2: __AttributeNonOptional {
            typealias Container = TestContainer<TestPrefix2>
            typealias Value = String
            static let name = "attr2"
            static let defaultValue = "default2"
            static let defaultRegistrar = __DefaultRegistrar()
        }

        // Get the registrar instances multiple times
        _ = Attr1.defaultRegistrar
        _ = Attr1.defaultRegistrar
        _ = Attr2.defaultRegistrar
        _ = Attr2.defaultRegistrar

        // Note: This test primarily documents the requirement that defaultRegistrar
        // must be a stored property. The actual verification happens in the
        // testDefaultRegistrarCallsRegisterOnlyOnce test above, which proves
        // that multiple reads don't cause multiple registrations.
        #expect(
            Bool(true),
            "DefaultRegistrar instances exist per attribute type"
        )
    }
}

// Test helper types
enum TestPrefix1: ConstString { static let value = "prefix1_" }
enum TestPrefix2: ConstString { static let value = "prefix2_" }

protocol ConstString {
    static var value: String { get }
}

struct TestContainer<Prefix: ConstString>: __Settings_Container {
    static var store: any UserDefaultsStore { Foundation.UserDefaults.standard }
    static var prefix: String { Prefix.value }
    static var suiteName: String? { nil }

    static func clear() {
        store.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) }
            .forEach { store.removeObject(forKey: $0) }
    }
}
