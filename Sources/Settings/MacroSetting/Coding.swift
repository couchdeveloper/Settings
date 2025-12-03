import Foundation

public protocol AttributeEncoding {
    func encode<Value: Encodable>(_ value: Value) throws -> Any
}

public protocol AttributeDecoding {
    func decode<Value: Decodable>(from: Any) throws -> Value
}

extension Foundation.JSONEncoder: AttributeEncoding {
    public func encode<Value: Encodable>(_ value: Value) throws -> Any {
        let data: Data = try self.encode(value)
        return data as Any
    }
}

extension Foundation.JSONDecoder: AttributeDecoding {
    public func decode<T>(from object: Any) throws -> T where T: Decodable {
        guard let data = object as? Data else {
            throw DecodingError(message: "Input needs to be a Data value")
        }
        return try self.decode(T.self, from: data)
    }
}

extension Foundation.PropertyListEncoder: AttributeEncoding {
    public func encode<Value: Encodable>(_ value: Value) throws -> Any {
        let plist: Data = try self.encode(value)
        return plist
    }
}

extension Foundation.PropertyListDecoder: AttributeDecoding {
    public func decode<T>(from object: Any) throws -> T where T: Decodable {
        guard let data = object as? Data else {
            throw DecodingError(message: "Input needs to be a Data value")
        }
        return try self.decode(T.self, from: data)
    }
}

// MARK: - Internal

struct DecodingError: LocalizedError {
    var message: String
    var errorDescription: String? {
        message
    }
}

struct EncodingError: LocalizedError {
    var message: String
    var errorDescription: String? {
        message
    }
}

