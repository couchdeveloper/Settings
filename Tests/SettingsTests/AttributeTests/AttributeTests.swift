import Testing
import Foundation
import Settings
import Combine

struct AttributeTests {
    
    protocol ConstString {
        static var value: String { get }
    }

    struct TestContainer<Prefix: ConstString>: __Settings_Container {
        static var store: UserDefaults { UserDefaults.standard }
        static var prefix: String { Prefix.value }
        
        static func clear() {
            for key in keys {
                store.removeObject(forKey: key)
            }
        }
        static var allKeys: [String] {
            Array(store.dictionaryRepresentation().keys)
        }
        
        static var keys: [String] {
            Array(store.dictionaryRepresentation().keys).filter { $0.hasPrefix(prefix) }
        }
    }


    @Test("Key composition - prefix + name")
    func testKeyComposition() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_key_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = String
            static let name = "compose"
            static let defaultValue = "default"
            static let defaultRegistrar = __DefaultRegistrar()
        }
        
        // Write a value via the typed API
        C[Attr.self] = "value"
        
        // Expected full key is container prefix + attribute name
        let expectedFullKey = C.prefix + Attr.name
        
        // Assert the underlying store has exactly that full key, and not the bare name
        #expect(C.allKeys.contains(expectedFullKey))
        #expect(!C.allKeys.contains(Attr.name))
        
        // Read directly from the store to verify composition
        #expect(C.store.string(forKey: expectedFullKey) == "value")
        
        // Sanity: typed read still returns the written value
        #expect(C[Attr.self] == "value")
    }
    
    @Test("Bool - Non-Optional")
    func testBoolNonOptional() async throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_bool_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Bool
            static let name = "nonOptional"
            static let defaultValue = true
            static let defaultRegistrar = __DefaultRegistrar()
        }
        #expect(C[Attr.self] == true)
        C[Attr.self] = false
        #expect(C[Attr.self] == false)
        Attr.reset()
        #expect(C[Attr.self] == true)
    }

    @Test("Int - Non-Optional")
    func testIntNonOptional() async throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_int_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Int
            static let name = "nonOptional"
            static let defaultValue = 42
            static let defaultRegistrar = __DefaultRegistrar()
        }
        #expect(C[Attr.self] == 42)
        C[Attr.self] = -7
        #expect(C[Attr.self] == -7)
        Attr.reset()
        #expect(C[Attr.self] == 42)
    }

    @Test("Float - Non-Optional")
    func testFloatNonOptional() async throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_float_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Float
            static let name = "nonOptional"
            static let defaultValue: Float = 3.5
            static let defaultRegistrar = __DefaultRegistrar()
        }
        #expect(C[Attr.self] == 3.5)
        C[Attr.self] = -2.25
        #expect(C[Attr.self] == -2.25)
        Attr.reset()
        #expect(C[Attr.self] == 3.5)
    }

    @Test("Double - Non-Optional")
    func testDoubleNonOptional() async throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_double_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Double
            static let name = "nonOptional"
            static let defaultValue = 3.5
            static let defaultRegistrar = __DefaultRegistrar()
        }
        #expect(C[Attr.self] == 3.5)
        C[Attr.self] = -2.25
        #expect(C[Attr.self] == -2.25)
        Attr.reset()
        #expect(C[Attr.self] == 3.5)
    }

    @Test("String - Non-Optional")
    func testStringNonOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_string_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeNonOptional { typealias Container = C
            typealias Value = String
            static let name = "nonOptional"
            static let defaultValue = "default"
            static let defaultRegistrar = __DefaultRegistrar()
        }
        #expect(C[Attr.self] == "default")
        C[Attr.self] = "Hello"
        #expect(C[Attr.self] == "Hello")
        C[Attr.self] = "Unicode 🎉"
        #expect(C[Attr.self] == "Unicode 🎉")
        Attr.reset()
        #expect(C[Attr.self] == "default")
    }

    @Test("URL - Non-Optional")
    func testURLNonOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_url_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
    enum Attr: __AttributeNonOptional {
        typealias Container = C
        typealias Value = URL
        static let name = "nonOptional"
        static let defaultValue = URL(string: "https://example.com")!
        static let defaultRegistrar = __DefaultRegistrar()
    }
        #expect(C[Attr.self].absoluteString == "https://example.com")
        let newURL = URL(string: "https://apple.com")!
        C[Attr.self] = newURL
        #expect(C[Attr.self] == newURL)
        Attr.reset()
        #expect(C[Attr.self] == URL(string: "https://example.com")!)
    }

    @Test("Date - Non-Optional")
    func testDateNonOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_date_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Date
            static let name = "nonOptional"
            static let defaultValue = Date(timeIntervalSince1970: 123456)
            static let defaultRegistrar = __DefaultRegistrar()
        }
        #expect(C[Attr.self].timeIntervalSince1970 == 123456)
        let now = Date()
        C[Attr.self] = now
        #expect(abs(C[Attr.self].timeIntervalSince1970 - now.timeIntervalSince1970) < 0.05)
        Attr.reset()
        #expect(C[Attr.self].timeIntervalSince1970 == 123456)
    }

    @Test("Data - Non-Optional")
    func testDataNonOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_data_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Data
            static let name = "nonOptional"
            static let defaultValue = Data([0x00, 0x01])
            static let defaultRegistrar = __DefaultRegistrar()
        }
        #expect(C[Attr.self] == Data([0x00, 0x01]))
        let payload = "Hello".data(using: .utf8)!
        C[Attr.self] = payload
        #expect(C[Attr.self] == payload)
        Attr.reset()
        #expect(C[Attr.self] == Data([0x00, 0x01]))
    }

    // MARK: - Optional Primitives

    @Test("Bool? - Optional including coercion")
    func testBoolOptionalAndCoercion() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_boolOpt_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = Bool?
            typealias Wrapped = Bool
            static let name = "optional"
        }
        
        #expect(C[Attr.self] == nil)
        C[Attr.self] = true
        #expect(C[Attr.self] == true)
        C[Attr.self] = false
        #expect(C[Attr.self] == false)
        C[Attr.self] = nil
        #expect(C[Attr.self] == nil)
        // Coercion behavior via direct store writes
        C.store.set(NSNumber(value: 1), forKey: Attr.key)
        #expect(C[Attr.self] == true)
        C.store.set("0", forKey: Attr.key)
        #expect(C[Attr.self] == false)
        C.store.set("yes", forKey: Attr.key)
        #expect(C[Attr.self] == true)
        C.store.set("off", forKey: Attr.key)
        #expect(C[Attr.self] == false)
        C.store.set(["unexpected"], forKey: Attr.key)
        #expect(C[Attr.self] == false)
        Attr.reset()
    }

    @Test("Int? - Optional")
    func testIntOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_intOpt_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = Int?
            typealias Wrapped = Int
            static let name = "optional"
        }
        #expect(C[Attr.self] == nil)
        C[Attr.self] = 7
        #expect(C[Attr.self] == 7)
        C[Attr.self] = nil
        #expect(C[Attr.self] == nil)
    }

    @Test("Float? - Optional")
    func testFloatOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_floatOpt_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = Float?
            typealias Wrapped = Float
            static let name = "optional"
        }
        #expect(C[Attr.self] == nil)
        C[Attr.self] = 2.75
        #expect(C[Attr.self] == 2.75)
        C[Attr.self] = nil
        #expect(C[Attr.self] == nil)
    }

    @Test("Double? - Optional")
    func testDoubleOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_doubleOpt_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = Double?
            typealias Wrapped = Double
            static let name = "optional"
        }
        #expect(C[Attr.self] == nil)
        C[Attr.self] = 2.75
        #expect(C[Attr.self] == 2.75)
        C[Attr.self] = nil
        #expect(C[Attr.self] == nil)
    }

    @Test("String? - Optional")
    func testStringOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_stringOpt_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum StringOpt: __AttributeOptional {
            typealias Container = C
            typealias Value = String?
            typealias Wrapped = String
            static let name = "optional"
        }
        #expect(C[StringOpt.self] == nil)
        C[StringOpt.self] = ""
        #expect(C[StringOpt.self] == "")
        C[StringOpt.self] = "Hello"
        #expect(C[StringOpt.self] == "Hello")
        C[StringOpt.self] = nil
        #expect(C[StringOpt.self] == nil)
    }

    @Test("URL? - Optional")
    func testURLOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_urlOpt_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = URL?
            typealias Wrapped = URL
            static let name = "optional"
        }
        #expect(C[Attr.self] == nil)
        let apple = URL(string: "https://apple.com")!
        C[Attr.self] = apple
        #expect(C[Attr.self] == apple)
        C[Attr.self] = nil
        #expect(C[Attr.self] == nil)
    }

    @Test("Date? - Optional")
    func testDateOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_dateOpt_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = Date?
            typealias Wrapped = Date
            static let name = "optional"
        }
        #expect(C[Attr.self] == nil)
        let d = Date()
        C[Attr.self] = d
        #expect(abs((C[Attr.self] ?? .distantPast).timeIntervalSince1970 - d.timeIntervalSince1970) < 0.05)
        C[Attr.self] = nil
        #expect(C[Attr.self] == nil)
    }

    @Test("Data? - Optional")
    func testDataOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_dataOpt_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = Data?
            typealias Wrapped = Data
            static let name = "optional"
        }
        #expect(C[Attr.self] == nil)
        let bytes = Data([0xAA, 0xBB])
        C[Attr.self] = bytes
        #expect(C[Attr.self] == bytes)
        C[Attr.self] = nil
        #expect(C[Attr.self] == nil)
    }

    // MARK: - Codable Collections

    @Test("Array Codable - Non-Optional")
    func testArrayCodableNonOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_arrayCodable_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = [String]
            static let name = "nonOptional"
            static let defaultValue = ["a", "b"]
            static let defaultRegistrar = __DefaultRegistrar()
        }
        #expect(C[Attr.self] == ["a", "b"])
        C[Attr.self] = ["one", "two"]
        #expect(C[Attr.self] == ["one", "two"])
        Attr.reset()
        #expect(C[Attr.self] == ["a", "b"])
    }

    @Test("Dictionary Codable - Optional")
    func testDictionaryCodableOptional() throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_dictCodableOpt_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }
        
        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = [String: Int]?
            typealias Wrapped = [String: Int]
            static let name = "optional"
        }
        #expect(C[Attr.self] == nil)
        C[Attr.self] = ["x": 1, "y": 2]
        #expect(C[Attr.self] == ["x": 1, "y": 2])
        C[Attr.self] = [:]
        #expect(C[Attr.self] == [:])
        C[Attr.self] = nil
        #expect(C[Attr.self] == nil)
    }

    @Test("CustomCodable default registration encodes into store")
    func testCustomCodableDefaultRegistrationStoresEncodedDefault() async throws {
        enum Prefix: ConstString { static let value = "com_UserDefaultsTests_UserDefaultAttributeTests_customCodableDefault_" }
        typealias C = TestContainer<Prefix>
        defer { C.clear() }

        struct Settings: Codable, Equatable, _CustomCodableValue {
            var flag: Bool
            var count: Int
        }

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Settings
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
            static let name = "settings"
            static let defaultValue = Settings(flag: false, count: 0)
            static let defaultRegistrar = __DefaultRegistrar()
        }

        // Trigger default registration via a read
        let readValue = C[Attr.self]
        #expect(readValue == Settings(flag: false, count: 0))

        // Verify that the store now contains encoded data for the default
        let object = C.store.object(forKey: Attr.key)
        #expect(object != nil)
        if let object {
            do {
                let decoded = try Attr.decode(from: object)
                #expect(decoded == Settings(flag: false, count: 0))
            } catch {
                Issue.record("Decoding failed: \(error)")
            }
        }

        // Ensure re-registering doesn't overwrite a custom value
        C[Attr.self] = Settings(flag: true, count: 5)
        // Call registerDefault explicitly (should be a no-op now)
        Attr.registerDefault()
        #expect(C[Attr.self] == Settings(flag: true, count: 5))
    }

}
