import Combine
import Foundation

// MARK: - __AttributeNonOptional

public protocol __AttributeNonOptional<Container>: __Attribute {
    associatedtype Value
    associatedtype Encoder = Never
    associatedtype Decoder = Never

    static var defaultValue: Value { get }
    static var defaultRegistrar: __DefaultRegistrar { get }

    static var encoder: Encoder { get }
    static var decoder: Decoder { get }

    static func encode(_ value: Value) throws -> Any
    static func decode(from object: Any) throws -> Value
}

// MARK: - Default Implementations

extension __AttributeNonOptional {
    
    public static func registerDefault() {
        registerDefaultIfNeeded()
    }
    
    static func registerDefaultIfNeeded() {
        defaultRegistrar.registerDefaultIfNeeded(
            container: Container.self,
            key: key,
            encodedDefaultValue: try encode(defaultValue)
        )
    }
}

// MARK: - Read / Write

extension __AttributeNonOptional where Value == Bool {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        return Container.bool(forKey: key)
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

extension __AttributeNonOptional where Value == Int {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        return Container.integer(forKey: key)
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

extension __AttributeNonOptional where Value == Double {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        return Container.double(forKey: key)
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

extension __AttributeNonOptional where Value == Float {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        return Container.float(forKey: key)
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

extension __AttributeNonOptional where Value == String {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        return Container.string(forKey: key) ?? defaultValue
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

extension __AttributeNonOptional where Value == URL {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        return Container.url(forKey: key) ?? defaultValue
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

extension __AttributeNonOptional where Value == Date {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        guard let any = Container.object(forKey: key), let date = any as? Date
        else {
            return defaultValue
        }
        return date
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

extension __AttributeNonOptional where Value == Data {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        guard let data = Container.data(forKey: key) else {
            return defaultValue
        }
        return data
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

extension __AttributeNonOptional where Value == [Any] {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        guard let array = Container.array(forKey: key) else {
            fatalError("user default value cannot be interpreted as Array<Any>")
        }
        return array
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

// Specific extensions for typed arrays to avoid ambiguity with [Any]
extension __AttributeNonOptional where Value == [String] {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        guard let array = Container.array(forKey: key) as? Value else {
            return defaultValue
        }
        return array
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

extension __AttributeNonOptional where Value == [Int] {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        guard let array = Container.array(forKey: key) as? Value else {
            return defaultValue
        }
        return array
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

extension __AttributeNonOptional where Value == [Double] {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        guard let array = Container.array(forKey: key) as? Value else {
            return defaultValue
        }
        return array
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

extension __AttributeNonOptional where Value == [String: Any] {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        guard let dictionary = Container.dictionary(forKey: key) else {
            fatalError(
                "user default value cannot be interpreted as Dictionary<String, Any>"
            )
        }
        return dictionary
    }
    public static func write(value: Value) {
        Container.set(value, forKey: key)
    }
}

// MARK: - Codable Non-Optional

extension __AttributeNonOptional where Value: Codable {
    public static func read() -> Value {
        registerDefaultIfNeeded()
        guard let object = Container.object(forKey: key) else {
            fatalError("user default value for key \"\(key)\" cannot be read")
        }
        do {
            return try decode(from: object)
        } catch {
            fatalError(
                "user default value for key \"\(key)\" cannot be decoded as `\(Value.self)`"
            )
        }
    }
    public static func write(value: Value) {
        do {
            let object = try encode(value)
            Container.set(object, forKey: key)
        } catch {
            fatalError(
                "Could not encode value of type `\(Value.self)` for key \(key): \(error)"
            )
        }
    }
}

// MARK: - NonOptional - Encoding / Decoding

// MARK: Value is a PropertyListValue

extension __AttributeNonOptional where Value: PropertyListValue {

    public static var encoder: Never { fatalError() }
    public static var decoder: Never { fatalError() }

    public static func encode(_ value: Value) throws -> Any {
        value
    }

    public static func decode(from object: Any) throws -> Value {
        guard let value = object as? Value else {
            throw DecodingError(
                message: "Cannot interpret given object as \(Value.self)"
            )
        }
        return value
    }
}

// MARK: Value is a PropertyListValue and Value is a Custom Codable

// For custom types that are both PropertyListValue and Codable, use their encoder/decoder
// This allows storing composite types as native plists via PropertyListEncoder
extension __AttributeNonOptional
where
    Value: PropertyListValue, Value: Codable,
    Encoder: AttributeEncoding,
    Decoder: AttributeDecoding
{
    public static func encode(_ value: Value) throws -> Any {
        try encoder.encode(value)
    }

    public static func decode(from object: Any) throws -> Value {
        try decoder.decode(from: object)
    }
}


// MARK: Value is Custom Codable

extension __AttributeNonOptional
where
    Value: Codable,
    Encoder: AttributeEncoding,
    Decoder: AttributeDecoding
{
    public static func encode(_ value: Value) throws -> Any {
        try encoder.encode(value)
    }

    public static func decode(from object: Any) throws -> Value {
        try decoder.decode(from: object)
    }
}

// MARK: - Special Value is: [Any]

extension __AttributeNonOptional where Value == [Any] {
    public static var encoder: Never { fatalError() }
    public static var decoder: Never { fatalError() }

    public static func encode(_ value: Value) throws -> Any {
        value
    }

    public static func decode(from object: Any) throws -> Value {
        guard let value = object as? Value else {
            throw DecodingError(
                message: "Cannot interpret given object as [Any]"
            )
        }
        return value
    }
}

// MARK: - Special Value is: [String: Any]

extension __AttributeNonOptional where Value == [String: Any] {
    public static var encoder: Never { fatalError() }
    public static var decoder: Never { fatalError() }

    public static func encode(_ value: Value) throws -> Any {
        value
    }

    public static func decode(from object: Any) throws -> Value {
        guard let value = object as? Value else {
            throw DecodingError(
                message: "Cannot interpret given object as [String: Any]"
            )
        }
        return value
    }
}

// MARK: - Special: URL

func encodeUrl(_ url: URL) throws -> Any {
    try NSKeyedArchiver.archivedData(
        withRootObject: url,
        requiringSecureCoding: true
    )
}

func decodeUrl(from object: Any) throws -> URL {
    switch object {
    case let string as String:
        return URL(string: string)!
    case let url as URL:
        return url
    case let data as Data:
        do {
            let any = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSURL.self, from: data)
            guard let url = any as? URL else {
                fatalError("could not interpret user default object as URL")
            }
            return url
        } catch {
            fatalError(error.localizedDescription)
        }
    default:
        fatalError("could not interpret user default object as URL")
    }
}

extension __AttributeNonOptional where Value == URL {
    public static var encoder: Never { fatalError() }
    public static var decoder: Never { fatalError() }

    public static func encode(_ value: Value) throws -> Any {
        try encodeUrl(value)
    }
    
    public static func decode(from object: Any) throws -> Value {
        try decodeUrl(from: object)
    }
}

