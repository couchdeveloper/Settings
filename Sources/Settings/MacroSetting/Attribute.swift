import Combine
import Foundation

public protocol __Attribute<Container>: SendableMetatype {
    associatedtype Container: __Settings_Container
    associatedtype Value
    
    static var name: String { get }
    
    static func read() -> Value
    static func write(value: Value)
    
    static func reset()
    
    static func registerDefault()
    
    static var stream: AsyncThrowingStream<Value, Error> { get }
    
    static func stream<Subject>(
        for keyPath: KeyPath<Value, Subject>
    ) -> AsyncThrowingStream<Subject, Error> where Subject: Equatable, Subject: Sendable
}

extension __Attribute {

    public static var key: String { "\(Container.prefix)\(name)" }

    /// Reset the value to its default by removing it from storage
    public static func reset() {
        Container.removeObject(forKey: key)
    }
    
}

public protocol PropertyListValue {}


// MARK: - Internal

extension Bool: PropertyListValue {}
extension Int: PropertyListValue {}
extension Float: PropertyListValue {}
extension Double: PropertyListValue {}
extension String: PropertyListValue {}
extension Date: PropertyListValue {}
extension Data: PropertyListValue {}


// Arrays are PropertyListValue only when their elements are PropertyListValue
// This prevents Array<SomeCodableType> from being treated as PropertyListValue
extension Array: PropertyListValue where Element: PropertyListValue {}

// Dictionaries are PropertyListValue only when their values are PropertyListValue
extension Dictionary: PropertyListValue
where Key == String, Value: PropertyListValue {}

typealias PropertyListArray = [Any]
typealias PropertyListDictionary = [String: Any]

