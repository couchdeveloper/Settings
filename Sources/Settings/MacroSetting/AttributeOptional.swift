import Combine
import Foundation

public protocol __AttributeOptional<Container>: __Attribute {
    associatedtype Value
    associatedtype Wrapped = Value
    associatedtype Encoder = Never
    associatedtype Decoder = Never

    static var encoder: Encoder { get }
    static var decoder: Decoder { get }

    static func encode(_ value: Value) throws -> Any
    static func decode(from object: Any) throws -> Value
}

extension __AttributeOptional {
    public static func registerDefault() { /* nothing */ }
}

// MARK: - Read / Write

extension __AttributeOptional where Value == Optional<Bool>, Wrapped == Bool {
    
    public static func read() -> Value {
        guard let any = Container.object(forKey: key) else {
            return nil
        }
        let coerced: Bool
        switch any {
        case let b as Bool:
            coerced = b
        case let n as NSNumber:
            // NSNumber covers CFBoolean and numeric values
            coerced = n.boolValue
        case let s as NSString:
            // Attempt to coerce common string representations
            let str = s.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if let intVal = Int(str) {
                coerced = intVal != 0
            } else if ["true", "yes", "y", "on"].contains(str) {
                coerced = true
            } else if ["false", "no", "n", "off"].contains(str) {
                coerced = false
            } else {
                // Match UserDefaults' behavior: non-coercible strings yield false
                coerced = false
            }
        default:
            // For unsupported types, mirror UserDefaults.bool(forKey:) which yields false
            coerced = false
        }
        return coerced
    }
    
    public static func write(value: Value) {
        if let value {
            Container.set(value, forKey: key)
        } else {
            Container.removeObject(forKey: key)
        }
    }
}

extension __AttributeOptional where Value == Optional<Int>, Wrapped == Int {
    public static func read() -> Value {
        // TODO: improve
        guard Container.object(forKey: key) != nil else { return nil }
        return Container.integer(forKey: key)
    }
    public static func write(value: Value) {
        if let value {
            Container.set(value, forKey: key)
        } else {
            Container.removeObject(forKey: key)
        }
    }
}

extension __AttributeOptional where Value == Optional<Double>, Wrapped == Double {
    public static func read() -> Value {
        // TODO: improve
        guard Container.object(forKey: key) != nil else { return nil }
        return Container.double(forKey: key)
    }
    public static func write(value: Value) {
        if let value {
            Container.set(value, forKey: key)
        } else {
            Container.removeObject(forKey: key)
        }
    }
}

extension __AttributeOptional where Value == Optional<Float>, Wrapped == Float {
    public static func read() -> Value {
        // TODO: improve
        guard Container.object(forKey: key) != nil else { return nil }
        return Container.float(forKey: key)
    }
    public static func write(value: Value) {
        if let value {
            Container.set(value, forKey: key)
        } else {
            Container.removeObject(forKey: key)
        }
    }
}

extension __AttributeOptional where Value == Optional<String>, Wrapped == String {
    public static func read() -> Value {
        return Container.string(forKey: key)
    }
    public static func write(value: Value) {
        if let value {
            Container.set(value, forKey: key)
        } else {
            Container.removeObject(forKey: key)
        }
    }
}

extension __AttributeOptional where Value == Optional<URL>, Wrapped == URL {
    public static func read() -> Value {
        return Container.url(forKey: key)
    }
    public static func write(value: Value) {
        if let value {
            Container.set(value, forKey: key)
        } else {
            Container.removeObject(forKey: key)
        }
    }
}

extension __AttributeOptional where Value == Optional<Date>, Wrapped == Date {
    public static func read() -> Value {
        return Container.object(forKey: key) as? Date
    }
    public static func write(value: Value) {
        if let value {
            Container.set(value, forKey: key)
        } else {
            Container.removeObject(forKey: key)
        }
    }
}

extension __AttributeOptional where Value == Optional<Data>, Wrapped == Data {
    public static func read() -> Value {
        return Container.data(forKey: key)
    }
    public static func write(value: Value) {
        if let value {
            Container.set(value, forKey: key)
        } else {
            Container.removeObject(forKey: key)
        }
    }
}

extension __AttributeOptional where Value == Optional<[Any]>, Wrapped == [Any] {
    public static func read() -> Value {
        return Container.array(forKey: key)
    }
    public static func write(value: Value) {
        if let value {
            Container.set(value, forKey: key)
        } else {
            Container.removeObject(forKey: key)
        }
    }
}

extension __AttributeOptional where Value == Optional<[String: Any]>, Wrapped == [String: Any] {
    public static func read() -> Value {
        return Container.dictionary(forKey: key)
    }
    public static func write(value: Value) {
        if let value {
            Container.set(value, forKey: key)
        } else {
            Container.removeObject(forKey: key)
        }
    }
}

// MARK: - Optional Codable

extension __AttributeOptional where Value: Codable, Value == Optional<Wrapped> {
    public static func read() -> Value {
        guard let object = Container.object(forKey: key) else {
            return nil
        }
        do {
            return try decode(from: object)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    public static func write(value: Value) {
        if let unwrapped = value {
            do {
                let object = try encode(unwrapped)
                Container.set(object, forKey: key)
            } catch {
                fatalError(error.localizedDescription)
            }
        } else {
            Container.removeObject(forKey: key)
        }
    }
}

// MARK: - Optional - Encoding / Decoding

// MARK: Value is Optional and Wrapped is a PropertyListValue

extension __AttributeOptional where Wrapped: PropertyListValue, Value == Wrapped? {
    public static var encoder: Never { fatalError() }
    public static var decoder: Never { fatalError() }

    public static func encode(_ value: Value) throws -> Any {
        guard let wrapped = value else {
            fatalError() // we never call encode for optionals!
        }
        return wrapped as Any
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

// MARK: Value is an Optional, Wrapped is Custom Codable

extension __AttributeOptional
where
    Wrapped: Codable, Value == Wrapped?,
    Encoder: AttributeEncoding,
    Decoder: AttributeDecoding
{
    public static func encode(_ value: Value) throws -> Any {
        guard let wrapped = value else {
            fatalError() // Note: encode will never be called when Value is an Optional
        }
        return try encoder.encode(wrapped)
    }

    public static func decode(from object: Any) throws -> Value {
        return try decoder.decode(from: object)
    }
}

// MARK: - Special: [Any]?

extension __AttributeOptional where Wrapped == [Any], Value == Wrapped? {
    public static var encoder: Never { fatalError() }
    public static var decoder: Never { fatalError() }

    public static func encode(_ value: Value) throws -> Any {
        guard let value else {
            fatalError() // we never call encode when value equals nil
        }
        return value
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

// MARK: - Special: [String: Any]?

extension __AttributeOptional where Value == [String: Any]?, Wrapped == [String: Any] {
    public static var encoder: Never { fatalError() }
    public static var decoder: Never { fatalError() }

    public static func encode(_ value: Value) throws -> Any {
        guard let value else {
            fatalError() // we never call encode when value equals nil
        }
        return value
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

// MARK: - Special: URL?

extension __AttributeOptional where Value == URL? {
    public static var encoder: Never { fatalError() }
    public static var decoder: Never { fatalError() }

    public static func encode(_ value: Value) throws -> Any {
        guard let value else {
            throw EncodingError(message: "Cannot encode nil URL")
        }
        return try encodeUrl(value)
    }

    public static func decode(from object: Any) throws -> Value {
        switch object {
        case is NSNull:
            return nil
        default:
            return try decodeUrl(from: object)
        }
    }
}
