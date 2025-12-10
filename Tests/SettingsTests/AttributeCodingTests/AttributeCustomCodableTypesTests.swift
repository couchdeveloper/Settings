import Foundation
import Settings
import Testing

/// Tests for encoding/decoding of UserDefault values
/// Verifies JSON and PropertyList encoding/decoding work correctly
struct AttributeCustomCodableTypesTests {

    protocol ConstString {
        static var value: String { get }
    }

    struct TestContainer<Prefix: ConstString>: __Settings_Container {
        static var store: any UserDefaultsStore { UserDefaults.standard }
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
}

// MARK: - Codable Types for Testing

extension AttributeCustomCodableTypesTests {

    struct SimpleStruct: Codable, Equatable {
        let name: String
        let age: Int
        let isActive: Bool
    }

    struct NestedStruct: Codable, Equatable {
        let id: String
        let metadata: Metadata
        let tags: [String]

        struct Metadata: Codable, Equatable {
            let created: Date
            let version: String
        }
    }

    struct ComplexStruct: Codable, Equatable {
        let title: String
        let count: Int
        let rating: Double
        let data: Data
        let timestamp: Date
        let url: URL
        let items: [String]
        let options: [String: String]
    }

    enum Status: String, Codable, Equatable {
        case pending
        case active
        case completed
        case failed
    }

    struct StructWithEnum: Codable, Equatable {
        let id: String
        let status: Status
    }
}

// MARK: - JSON Encoding Tests

extension AttributeCustomCodableTypesTests {

    @Test func testJSONEncoding_SimpleStruct() async throws {
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
        guard let stored = UserDefaults.standard.object(forKey: Attr.key) else {
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

    @Test func testJSONEncoding_NestedStruct() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_JSONNested_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = NestedStruct
            static let name = "nestedStruct"
            static let defaultValue = NestedStruct(
                id: "default",
                metadata: NestedStruct.Metadata(
                    created: Date(timeIntervalSince1970: 0),
                    version: "1.0"
                ),
                tags: []
            )
            static let defaultRegistrar = __DefaultRegistrar()
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }
        defer { C.clear() }

        let original = NestedStruct(
            id: "test-123",
            metadata: NestedStruct.Metadata(
                created: Date(timeIntervalSince1970: 1_234_567_890),
                version: "2.5.1"
            ),
            tags: ["swift", "testing", "userdefaults"]
        )

        Attr.write(value: original)
        let decoded = Attr.read()

        #expect(decoded == original)
        #expect(decoded.id == "test-123")
        #expect(decoded.metadata.version == "2.5.1")
        #expect(decoded.tags.count == 3)
    }

    @Test func testJSONEncoding_ComplexStruct() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_JSONComplex_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = ComplexStruct
            static let name = "complexStruct"
            static let defaultValue = ComplexStruct(
                title: "Default",
                count: 0,
                rating: 0.0,
                data: Data(),
                timestamp: Date(timeIntervalSince1970: 0),
                url: URL(string: "https://example.com")!,
                items: [],
                options: [:]
            )
            static let defaultRegistrar = __DefaultRegistrar()
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }
        defer { C.clear() }

        let original = ComplexStruct(
            title: "Test Item",
            count: 42,
            rating: 4.7,
            data: Data([0x01, 0x02, 0x03]),
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            url: URL(string: "https://apple.com")!,
            items: ["one", "two", "three"],
            options: ["key1": "value1", "key2": "value2"]
        )

        Attr.write(value: original)
        let decoded = Attr.read()

        #expect(decoded == original)
        #expect(decoded.title == "Test Item")
        #expect(decoded.count == 42)
        #expect(decoded.rating == 4.7)
        #expect(decoded.data == Data([0x01, 0x02, 0x03]))
        #expect(decoded.items == ["one", "two", "three"])
        #expect(decoded.options == ["key1": "value1", "key2": "value2"])
    }

    @Test func testJSONEncoding_Array() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_JSONArray_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = [SimpleStruct]
            static let name = "arrayStruct"
            static let defaultValue: [SimpleStruct] = []
            static let defaultRegistrar = __DefaultRegistrar()
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }
        defer { C.clear() }

        let original = [
            SimpleStruct(name: "Alice", age: 30, isActive: true),
            SimpleStruct(name: "Bob", age: 25, isActive: false),
            SimpleStruct(name: "Charlie", age: 35, isActive: true),
        ]

        Attr.write(value: original)
        let decoded = Attr.read()

        #expect(decoded.count == 3)
        #expect(decoded == original)
        #expect(decoded[0].name == "Alice")
        #expect(decoded[1].age == 25)
        #expect(decoded[2].isActive == true)
    }

    @Test func testJSONEncoding_Dictionary() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_JSONDict_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = [String: SimpleStruct]
            static let name = "dictStruct"
            static let defaultValue: [String: SimpleStruct] = [:]
            static let defaultRegistrar = __DefaultRegistrar()
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }
        defer { C.clear() }

        let original = [
            "user1": SimpleStruct(name: "Alice", age: 30, isActive: true),
            "user2": SimpleStruct(name: "Bob", age: 25, isActive: false),
        ]

        Attr.write(value: original)
        let decoded = Attr.read()

        #expect(decoded.count == 2)
        #expect(decoded["user1"]?.name == "Alice")
        #expect(decoded["user2"]?.age == 25)
    }

    @Test func testJSONEncoding_Enum() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_JSONEnum_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = StructWithEnum
            static let name = "structWithEnum"
            static let defaultValue = StructWithEnum(
                id: "default",
                status: .pending
            )
            static let defaultRegistrar = __DefaultRegistrar()
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }
        defer { C.clear() }

        let original = StructWithEnum(id: "task-123", status: .completed)

        Attr.write(value: original)
        let decoded = Attr.read()

        #expect(decoded == original)
        #expect(decoded.id == "task-123")
        #expect(decoded.status == .completed)
    }
}

// MARK: - PropertyList Encoding Tests

extension AttributeCustomCodableTypesTests {

    @Test func testPropertyListEncoding_NativeTypes() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_PlistNative_"
        }
        typealias C = TestContainer<Prefix>

        // String
        enum StringAttr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = String
            static let name = "string"
            static let defaultValue = "default"
            static let defaultRegistrar = __DefaultRegistrar()
        }

        // Int
        enum IntAttr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Int
            static let name = "int"
            static let defaultValue = 0
            static let defaultRegistrar = __DefaultRegistrar()
        }

        // Array
        enum ArrayAttr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = [String]
            static let name = "array"
            static let defaultValue: [String] = []
            static let defaultRegistrar = __DefaultRegistrar()
        }

        // Dictionary
        enum DictAttr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = [String: Int]
            static let name = "dict"
            static let defaultValue: [String: Int] = [:]
            static let defaultRegistrar = __DefaultRegistrar()
        }

        defer { C.clear() }

        // These should be stored as native PropertyList types, not encoded
        StringAttr.write(value: "test")
        IntAttr.write(value: 42)
        ArrayAttr.write(value: ["a", "b", "c"])
        DictAttr.write(value: ["x": 1, "y": 2])

        // Verify stored as native types
        let stringObj = UserDefaults.standard.object(forKey: StringAttr.key)
        let intObj = UserDefaults.standard.object(forKey: IntAttr.key)
        let arrayObj = UserDefaults.standard.object(forKey: ArrayAttr.key)
        let dictObj = UserDefaults.standard.object(forKey: DictAttr.key)

        #expect(stringObj is String)
        #expect(intObj is NSNumber)
        #expect(arrayObj is NSArray)
        #expect(dictObj is NSDictionary)

        // Verify values
        #expect(StringAttr.read() == "test")
        #expect(IntAttr.read() == 42)
        #expect(ArrayAttr.read() == ["a", "b", "c"])
        #expect(DictAttr.read() == ["x": 1, "y": 2])
    }

    @Test func testPropertyListEncoding_CodableTypes() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_PlistCodable_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = SimpleStruct
            static let name = "codableStruct"
            static let defaultValue = SimpleStruct(
                name: "Default",
                age: 0,
                isActive: false
            )
            static let defaultRegistrar = __DefaultRegistrar()
            static var encoder: PropertyListEncoder { PropertyListEncoder() }
            static var decoder: PropertyListDecoder { PropertyListDecoder() }
        }
        defer { C.clear() }

        let original = SimpleStruct(name: "Test", age: 42, isActive: true)

        Attr.write(value: original)

        // Codable types should be stored as Data
        let stored = UserDefaults.standard.object(forKey: Attr.key)
        #expect(stored is Data)

        let decoded = Attr.read()
        #expect(decoded == original)
    }
}

// MARK: - Optional Encoding Tests

extension AttributeCustomCodableTypesTests {

    @Test func testOptionalEncoding_Nil() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_OptionalNil_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Value = SimpleStruct?
            typealias Wrapped = SimpleStruct
            typealias Container = C
            static let name = "optionalStruct"
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }
        defer { C.clear() }

        // Write nil
        Attr.write(value: nil)

        // Verify key doesn't exist
        let stored = UserDefaults.standard.object(forKey: Attr.key)
        #expect(stored == nil)

        // Read should return nil
        let decoded = Attr.read()
        #expect(decoded == nil)
    }

    @Test func testOptionalEncoding_Value() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_OptionalValue_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = SimpleStruct?
            typealias Wrapped = SimpleStruct
            static let name = "optionalStruct"
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }
        defer { C.clear() }

        let original = SimpleStruct(name: "Test", age: 30, isActive: true)

        // Write value
        Attr.write(value: original)

        // Should be stored
        let stored = UserDefaults.standard.object(forKey: Attr.key)
        #expect(stored != nil)

        // Read should return value
        let decoded = Attr.read()
        #expect(decoded == original)

        // Write nil and verify removal
        Attr.write(value: nil)
        let storedAfterNil = UserDefaults.standard.object(forKey: Attr.key)
        #expect(storedAfterNil == nil)
    }

    @Test func testOptionalEncoding_ToggleBetweenNilAndValue() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_OptionalToggle_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = SimpleStruct?
            typealias Wrapped = SimpleStruct
            static let name = "optionalStruct"
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }
        defer { C.clear() }

        let value1 = SimpleStruct(name: "First", age: 20, isActive: true)
        let value2 = SimpleStruct(name: "Second", age: 30, isActive: false)

        // Write, read, verify
        Attr.write(value: value1)
        #expect(Attr.read() == value1)

        // Write nil, read, verify
        Attr.write(value: nil)
        #expect(Attr.read() == nil)

        // Write different value, read, verify
        Attr.write(value: value2)
        #expect(Attr.read() == value2)

        // Write nil again, read, verify
        Attr.write(value: nil)
        #expect(Attr.read() == nil)
    }
}

// MARK: - Round-Trip Tests

extension AttributeCustomCodableTypesTests {

    @Test func testRoundTrip_MultipleWrites() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_RoundTrip_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = ComplexStruct
            static let name = "complexStruct"
            static let defaultValue = ComplexStruct(
                title: "Default",
                count: 0,
                rating: 0.0,
                data: Data(),
                timestamp: Date(timeIntervalSince1970: 0),
                url: URL(string: "https://example.com")!,
                items: [],
                options: [:]
            )
            static let defaultRegistrar = __DefaultRegistrar()
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }
        defer { C.clear() }

        // Write and read multiple times
        for i in 0..<5 {
            let value = ComplexStruct(
                title: "Item \(i)",
                count: i * 10,
                rating: Double(i) + 0.5,
                data: Data([UInt8(i)]),
                timestamp: Date(timeIntervalSince1970: Double(i * 1000)),
                url: URL(string: "https://example.com/\(i)")!,
                items: Array(repeating: "item", count: i),
                options: ["index": "\(i)"]
            )

            Attr.write(value: value)
            let decoded = Attr.read()

            #expect(decoded == value)
            #expect(decoded.title == "Item \(i)")
            #expect(decoded.count == i * 10)
        }
    }

    @Test func testRoundTrip_DefaultValue() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_RoundTripDefault_"
        }
        typealias C = TestContainer<Prefix>

        func makeDefaultValue() -> SimpleStruct {
            SimpleStruct(name: "Default", age: 99, isActive: false)
        }

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = SimpleStruct
            static let name = "struct"
            static let defaultValue = makeDefaultValue()
            static let defaultRegistrar = __DefaultRegistrar()
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }
        defer { C.clear() }

        // Read without writing - should get default
        Attr.registerDefault()
        UserDefaults.standard.removeObject(forKey: Attr.key)

        let initial = Attr.read()
        #expect(initial == makeDefaultValue())

        // Write new value
        let newValue = SimpleStruct(name: "Custom", age: 42, isActive: true)
        Attr.write(value: newValue)

        let afterWrite = Attr.read()
        #expect(afterWrite == newValue)

        // Reset and verify default is back
        Attr.reset()
        let afterReset = Attr.read()
        #expect(afterReset == makeDefaultValue())
    }
}

// MARK: - Error Handling Tests

extension AttributeCustomCodableTypesTests {

    @Test func testEncoding_CorruptedData() async throws {
        enum Prefix: ConstString {
            static let value = "com_EncodingTests_Corrupted_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = SimpleStruct
            static let name = "struct"
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

        // Manually write invalid data
        let corruptedData = Data([0xFF, 0xFF, 0xFF])
        UserDefaults.standard.set(corruptedData, forKey: Attr.key)

        // Attempting to read should fail gracefully
        // The implementation should either throw or return default
        // This tests that decode properly handles invalid data
        do {
            let object = UserDefaults.standard.object(forKey: Attr.key)!
            let _ = try Attr.decode(from: object)
            Issue.record("Expected decode to fail with corrupted data")
        } catch {
            // Expected to throw - any error is acceptable
            #expect(Bool(true))
        }
    }
}
