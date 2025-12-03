import Foundation
import Testing
import Settings
import SettingsMock

struct UserDefaultsStoreMockTests {
    
    protocol ConstString {
        static var value: String { get }
    }

    struct TestContainer<Prefix: ConstString>: __Settings_Container {
        static var store: UserDefaultsStoreMock { UserDefaultsStoreMock.standard }
        static var prefix: String { Prefix.value }

        static func clear() {
            for key in keys {
                store.removeObject(forKey: key)
            }
        }

        static var keys: [String] {
            Array(store.dictionaryRepresentation().keys).filter {
                $0.hasPrefix(prefix)
            }
        }
    }


    @Test("Defaults vs values precedence and removal restores default")
    func defaultsAndValuesPrecedence() async throws {
        let store = UserDefaultsStoreMock(store: [:])
        let key = "name"

        // Register a default and read it
        store.register(defaults: [key: "def"]) 
        #expect(store.string(forKey: key) == "def")
        #expect(store.object(forKey: key) as? String == "def")

        // Set a user value; user value should override default
        store.set("val", forKey: key)
        #expect(store.string(forKey: key) == "val")
        #expect(store.object(forKey: key) as? String == "val")

        // Removing the value should restore the default
        store.removeObject(forKey: key)
        #expect(store.string(forKey: key) == "def")
    }

    @Test("Reject non-property-list values on set and register")
    func serializationEnforced() async throws {
        final class NonPlist: NSObject {}
        let store = UserDefaultsStoreMock(store: [:])
        let key1 = "obj1"
        let key2 = "obj2"

        // Attempt to set a value that can't be represented as a property list
        store.set(NonPlist(), forKey: key1)
        #expect(store.object(forKey: key1) == nil)

        // Attempt to register a default that can't be represented as a property list
        store.register(defaults: [key2: NonPlist()])
        #expect(store.object(forKey: key2) == nil)
    }

    @MainActor
    @Test("Observer notifies on effective value changes")
    func observerNotifiesOnEffectiveChanges() async throws {
        struct Event: @unchecked Sendable {
            var old: Any?
            var new: Any?
        }
        let store = UserDefaultsStoreMock(store: [:])
        let key = "tracked"
        var events: [Event] = []

        let token = store.observer(forKey: key) { old, new in
            nonisolated(unsafe) let _old: Any? = old
            nonisolated(unsafe) let _new: Any? = new
            
            MainActor.assumeIsolated {
                events.append(Event(old: _old, new: _new))
            }
        }

        // Allow the initial KVO event to be delivered
        await Task.yield()

        // Register a default; expect a change from nil -> "d"
        store.register(defaults: [key: "d"]) 
        #expect(events.count >= 2)
        // Last event should reflect the change to default
        if let last = events.last {
            #expect((last.old as? String) == nil)
            #expect((last.new as? String) == "d")
        }

        // Set a user value; expect default -> user value
        store.set("v1", forKey: key)
        #expect(events.count >= 3)
        if let last = events.last {
            #expect((last.old as? String) == "d")
            #expect((last.new as? String) == "v1")
        }

        // Setting the same value again should not notify
        let before = events.count
        store.set("v1", forKey: key)
        await Task.yield()
        #expect(events.count == before)

        // Removing the value should restore the default and notify
        store.removeObject(forKey: key)
        #expect(events.count >= before + 1)
        if let last = events.last {
            #expect((last.old as? String) == "v1")
            #expect((last.new as? String) == "d")
        }
        _ = token // keep alive
    }
    
    @Test func testBool() async throws {
        enum Prefix: ConstString {
            static let value = "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testBool_"
        }
        typealias C = TestContainer<Prefix>
        
        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Bool
            static let name = "bool"
            static let defaultValue = false
            static let defaultRegistrar = __DefaultRegistrar()
        }
        
        #expect(Attr.Encoder.self == Never.self)
        #expect(Attr.Decoder.self == Never.self)
        
        let obj = try Attr.encode(true)
        #expect((obj as? Attr.Value) == true)
        let value = try Attr.decode(from: obj)
        #expect(value == true)
    }

    @Test func testJSONEncoding_SimpleStruct() async throws {
        struct SimpleStruct: Codable, Equatable {
            let name: String
            let age: Int
            let isActive: Bool
        }

        enum Prefix: ConstString {
            static let value = "com_EncodingTests_JSONSimple_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = SimpleStruct
            static let name = "simpleStruct"
            static let defaultValue = SimpleStruct(
                name: "Default",
                age: 0,
                isActive: false
            )
            static let defaultRegistrar = __DefaultRegistrar()
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }
        defer { C.clear() }

        let original = SimpleStruct(name: "Alice", age: 30, isActive: true)

        // Write using library
        Attr.write(value: original)

        // Read back
        let decoded = Attr.read()
        #expect(decoded == original)

        // Verify it's stored as Data (JSON encoded)
        guard let stored = Attr.Container.store.object(forKey: Attr.key) else {
            Issue.record("No object stored")
            return
        }
        #expect(stored is Data)

        // Verify we can decode it as JSON
        if let data = stored as? Data {
            let jsonDecoded = try JSONDecoder().decode(
                SimpleStruct.self,
                from: data
            )
            #expect(jsonDecoded == original)
        }
    }

}
