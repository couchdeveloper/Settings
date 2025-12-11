import Foundation
import Settings
import Testing

struct AttributeCodingTests {

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

// MARK: - Primitive Types
extension AttributeCodingTests {
    @Test func testBool() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testBool_"
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

    @Test func testOptionalBool() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalBool_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = Bool?
            typealias Wrapped = Bool
            static let name = "boolOpt"
        }

        #expect(Attr.Wrapped.self == Bool.self)
        #expect(Attr.Encoder.self == Never.self)
        #expect(Attr.Decoder.self == Never.self)

        let obj = try Attr.encode(true)
        #expect((obj as? Attr.Value) == true)
        let value = try Attr.decode(from: obj)
        #expect(value == true)
    }

    @Test func testInt() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testInt_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Int
            static let name = "int"
            static let defaultValue = -1
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let obj = try Attr.encode(7)
        #expect((obj as? Attr.Value) == 7)
        let value = try Attr.decode(from: obj)
        #expect(value == 7)
    }

    @Test func testOptionalInt() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalInt_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = Int?
            typealias Wrapped = Int
            static let name = "intOpt"
        }

        #expect(Attr.Wrapped.self == Int.self)

        let obj = try Attr.encode(7)
        #expect((obj as? Attr.Value) == 7)
        let value = try Attr.decode(from: obj)
        #expect(value == 7)
    }

    @Test func testFloat() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testFloat_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Float
            static let name = "float"
            static let defaultValue: Float = 0
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let obj = try Attr.encode(3.5)
        #expect((obj as? Attr.Value) == 3.5)
        let value = try Attr.decode(from: obj)
        #expect(value == 3.5)
    }

    @Test func testOptionalFloat() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalFloat_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = Float?
            typealias Wrapped = Float
            static let name = "floatOpt"
        }

        #expect(Attr.Wrapped.self == Float.self)

        let obj = try Attr.encode(3.5)
        #expect((obj as? Attr.Value) == 3.5)
        let value = try Attr.decode(from: obj)
        #expect(value == 3.5)
    }

    @Test func testDouble() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testDouble_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Double
            static let name = "double"
            static let defaultValue: Double = 0
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let obj = try Attr.encode(7.25)
        #expect((obj as? Attr.Value) == 7.25)
        let value = try Attr.decode(from: obj)
        #expect(value == 7.25)
    }

    @Test func testOptionalDouble() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalDouble_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = Double?
            typealias Wrapped = Double
            static let name = "doubleOpt"
        }

        #expect(Attr.Wrapped.self == Double.self)

        let obj = try Attr.encode(7.25)
        #expect((obj as? Attr.Value) == 7.25)
        let value = try Attr.decode(from: obj)
        #expect(value == 7.25)
    }

    @Test func testString() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testString_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = String
            static let name = "string"
            static let defaultValue: String = ""
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let obj = try Attr.encode("hello")
        #expect((obj as? Attr.Value) == "hello")
        let value = try Attr.decode(from: obj)
        #expect(value == "hello")
    }

    @Test func testOptionalString() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalString_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = String?
            typealias Wrapped = String
            static let name = "stringOpt"
        }

        #expect(Attr.Wrapped.self == String.self)

        let obj = try Attr.encode("hello")
        #expect((obj as? Attr.Value) == "hello")
        let value = try Attr.decode(from: obj)
        #expect(value == "hello")
    }

    @Test func testDate() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testDate_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Date
            static let name = "date"
            static let defaultValue = Date(timeIntervalSince1970: 0)
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let sample = Date(timeIntervalSince1970: 1_234_567)
        let obj = try Attr.encode(sample)
        #expect((obj as? Attr.Value) == sample)
        let value = try Attr.decode(from: obj)
        #expect(value == sample)
    }

    @Test func testOptionalDate() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalDate_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = Date?
            typealias Wrapped = Date
            static let name = "dateOpt"
        }

        let sample = Date(timeIntervalSince1970: 1_234_567)
        let obj = try Attr.encode(sample)
        #expect((obj as? Attr.Value) == sample)
        let value = try Attr.decode(from: obj)
        #expect(value == sample)
    }

    @Test func testData() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testData_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = Data
            static let name = "data"
            static let defaultValue = Data()
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let sample = Data([0x01, 0x02, 0x03])
        let obj = try Attr.encode(sample)
        #expect((obj as? Attr.Value) == sample)
        let value = try Attr.decode(from: obj)
        #expect(value == sample)
    }

    @Test func testOptionalData() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalData_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = Data?
            typealias Wrapped = Data
            static let name = "dataOpt"
        }

        let sample = Data([0x01, 0x02, 0x03])
        let obj = try Attr.encode(sample)
        #expect((obj as? Attr.Value) == sample)
        let value = try Attr.decode(from: obj)
        #expect(value == sample)
    }

}

// MARK: - Primitive URL
extension AttributeCodingTests {
    @Test func testURL() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testURL_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = URL
            static let name = "url"
            static let defaultValue = URL(string: "https://example.com")!
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let url = URL(string: "https://swift.org")!
        let encoded = try Attr.encode(url)
        let decoded = try Attr.decode(from: encoded)

        #expect(decoded == url)
    }

    @Test func testOptionalURL() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalURL_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = URL?
            typealias Wrapped = URL
            static let name = "urlOpt"
        }

        let url = URL(string: "https://swift.org")!
        let encoded = try Attr.encode(url)
        let decoded = try Attr.decode(from: encoded)

        #expect(decoded == url)
    }
}

// MARK: - Primitive Array

extension AttributeCodingTests {

    @Test func testArrayAny() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testArrayAny_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = [Any]
            static let name = "arrayAny"
            static var defaultValue: [Any] { [] }
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let sample: [Any] = ["a", 1, true]
        let obj = try Attr.encode(sample)
        let encoded = obj as? Attr.Value
        #expect(encoded != nil)
        #expect(encoded?.count == 3)
        #expect((encoded?[0] as? String) == "a")
        #expect((encoded?[1] as? Int) == 1)
        #expect((encoded?[2] as? Bool) == true)
        let value = try Attr.decode(from: obj)
        let decoded = value as [Any]
        #expect(decoded.count == 3)
        #expect((decoded[0] as? String) == "a")
        #expect((decoded[1] as? Int) == 1)
        #expect((decoded[2] as? Bool) == true)
    }

    @Test func testOptionalArrayAny() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalArrayAny_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = [Any]?
            typealias Wrapped = [Any]
            static let name = "arrayAnyOpt"
        }

        let sample: [Any] = ["a", 1, true]
        let obj = try Attr.encode(sample)
        let encoded = obj as? Attr.Value
        #expect(encoded != nil)
        let encodedArray = encoded!!
        #expect(encodedArray.count == 3)
        #expect((encodedArray[0] as? String) == "a")
        #expect((encodedArray[1] as? Int) == 1)
        #expect((encodedArray[2] as? Bool) == true)
        let value = try Attr.decode(from: obj)
        let decoded = value
        #expect(decoded != nil)
        let decodedArray = decoded!
        #expect(decodedArray.count == 3)
        #expect((decodedArray[0] as? String) == "a")
        #expect((decodedArray[1] as? Int) == 1)
        #expect((decodedArray[2] as? Bool) == true)
    }

    @Test func testArrayString() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testArrayString_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = [String]
            static let name = "arrayString"
            static let defaultValue: [String] = []
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let sample = ["a", "b", "c"]
        let obj = try Attr.encode(sample)
        #expect((obj as? Attr.Value) == sample)
        let value = try Attr.decode(from: obj)
        #expect(value == sample)
    }

    @Test func testOptionalArrayString() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalArrayString_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = [String]?
            typealias Wrapped = [String]
            static let name = "arrayStringOpt"
        }

        let sample = ["a", "b", "c"]
        let obj = try Attr.encode(sample)
        #expect((obj as? Attr.Value) == sample)
        let value = try Attr.decode(from: obj)
        #expect(value == sample)
    }
}

// MARK: - Primitive Dictionary

extension AttributeCodingTests {

    @Test func testDictionaryAny() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testDictionaryAny_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = [String: Any]
            static let name = "dictAny"
            static var defaultValue: [String: Any] { [:] }
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let sample: [String: Any] = [
            "s": "str",
            "i": 1,
            "b": true,
        ]
        let obj = try Attr.encode(sample)
        let encoded = obj as? Attr.Value
        #expect(encoded != nil)
        #expect((encoded?["s"] as? String) == "str")
        #expect((encoded?["i"] as? Int) == 1)
        #expect((encoded?["b"] as? Bool) == true)
        let value = try Attr.decode(from: obj)
        let decoded = value as [String: Any]
        #expect((decoded["s"] as? String) == "str")
        #expect((decoded["i"] as? Int) == 1)
        #expect((decoded["b"] as? Bool) == true)
    }

    @Test func testOptionalDictionaryAny() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalDictionaryAny_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = [String: Any]?
            typealias Wrapped = [String: Any]
            static let name = "dictAnyOpt"
        }

        let sample: [String: Any] = [
            "s": "str",
            "i": 1,
            "b": true,
        ]
        let obj = try Attr.encode(sample)
        let encoded = obj as? Attr.Value
        #expect(encoded != nil)
        let encodedDict = encoded!!
        #expect((encodedDict["s"] as? String) == "str")
        #expect((encodedDict["i"] as? Int) == 1)
        #expect((encodedDict["b"] as? Bool) == true)
        let value = try Attr.decode(from: obj)
        let decoded = value
        #expect(decoded != nil)
        let decodedDict = decoded!
        #expect((decodedDict["s"] as? String) == "str")
        #expect((decodedDict["i"] as? Int) == 1)
        #expect((decodedDict["b"] as? Bool) == true)
    }

    @Test func testDictionaryString() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testDictionaryString_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = [String: String]
            static let name = "dictString"
            static let defaultValue: [String: String] = [:]
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let sample = ["a": "1", "b": "2"]
        let obj = try Attr.encode(sample)
        #expect((obj as? Attr.Value) == sample)
        let value = try Attr.decode(from: obj)
        #expect(value == sample)
    }

    @Test func testOptionalDictionaryString() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalDictionaryString_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = [String: String]?
            typealias Wrapped = [String: String]
            static let name = "dictStringOpt"
        }

        let sample = ["a": "1", "b": "2"]
        let obj = try Attr.encode(sample)
        #expect((obj as? Attr.Value) == sample)
        let value = try Attr.decode(from: obj)
        #expect(value == sample)
    }
}

// MARK: Custom Codable Types
extension AttributeCodingTests {

    private struct CustomCodable: Codable, Equatable {
        let id: String
        let count: Int
        let flag: Bool
    }

    // MARK: Coding: JSON

    @Test func testCustomCodableJSON() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testCustomCodableJSON_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = CustomCodable
            static let name = "customJSON"
            static let defaultValue = CustomCodable(
                id: "default",
                count: 0,
                flag: false
            )
            static let defaultRegistrar = __DefaultRegistrar()
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }

        let original = CustomCodable(id: "abc", count: 7, flag: true)
        let obj = try Attr.encode(original)
        #expect(obj is Data)
        let value = try Attr.decode(from: obj)
        #expect(value == original)
    }

    @Test func testOptionalCustomCodableJSON() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalCustomCodableJSON_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = CustomCodable?
            typealias Wrapped = CustomCodable
            static let name = "customJSONOpt"
            static var encoder: JSONEncoder { JSONEncoder() }
            static var decoder: JSONDecoder { JSONDecoder() }
        }

        let original = CustomCodable(id: "xyz", count: 42, flag: false)
        let obj = try Attr.encode(original)
        #expect(obj is Data)
        let value = try Attr.decode(from: obj)
        #expect(value == original)
    }

    // MARK: Coding: PropertyList

    @Test func testCustomCodablePropertyList() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testCustomCodablePropertyList_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeNonOptional {
            typealias Container = C
            typealias Value = CustomCodable
            static let name = "customPlist"
            static let defaultValue = CustomCodable(
                id: "default",
                count: 0,
                flag: false
            )
            static let defaultRegistrar = __DefaultRegistrar()
            static var encoder: PropertyListEncoder { PropertyListEncoder() }
            static var decoder: PropertyListDecoder { PropertyListDecoder() }
        }

        let original = CustomCodable(id: "plist", count: 3, flag: true)
        let obj = try Attr.encode(original)
        #expect(obj is Data)
        let value = try Attr.decode(from: obj)
        #expect(value == original)
    }

    @Test func testOptionalCustomCodablePropertyList() async throws {
        enum Prefix: ConstString {
            static let value =
                "com_UserDefaultsTests_UserDefaultAttributeCodingTests_testOptionalCustomCodablePropertyList_"
        }
        typealias C = TestContainer<Prefix>

        enum Attr: __AttributeOptional {
            typealias Container = C
            typealias Value = CustomCodable?
            typealias Wrapped = CustomCodable
            static let name = "customPlistOpt"
            static var encoder: PropertyListEncoder { PropertyListEncoder() }
            static var decoder: PropertyListDecoder { PropertyListDecoder() }
        }

        let original = CustomCodable(id: "plistOpt", count: 5, flag: false)
        let obj = try Attr.encode(original)
        #expect(obj is Data)
        let value = try Attr.decode(from: obj)
        #expect(value == original)
    }

}
