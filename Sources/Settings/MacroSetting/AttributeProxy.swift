import Combine
import Foundation

/// A proxy object that provides observable access to a UserDefault property
/// This is the projected value type (accessed via `$propertyName`)
/// Public implementation that conforms to the public AttributeProxy protocol
public struct __AttributeProxy<A: __Attribute> where A.Container: __Settings_Container {

    public typealias Value = A.Value
    public typealias Container = A.Container
    public typealias Attribute = A

    public init(attributeType: A.Type) {}

    /// The current value (same as direct property access)
    public var wrappedValue: Value {
        get {
            A.read()
        }
        nonmutating set {
            A.write(value: newValue)
        }
    }

    /// Key used to store this value in UserDefaults
    public var key: String {
        A.key
    }

    /// Reset the value to its default
    public func reset() {
        A.reset()
    }
}

extension __AttributeProxy where A.Value: Sendable {

    public var stream: AsyncThrowingStream<Value, Error> {
        A.stream
    }

    public func stream<Subject>(
        for keyPath: KeyPath<Value, Subject>
    ) -> AsyncThrowingStream<Subject, Error>
    where Subject: Equatable, Subject: Sendable {
        A.stream(for: keyPath)
    }

    public var publisher: AnyPublisher<A.Value, any Error> {
        AsyncStreamPublisher(A.stream).eraseToAnyPublisher()
    }

    public func publisher<
        Subject
    >(
        for keyPath: KeyPath<A.Value, Subject>
    ) -> AnyPublisher<Subject, any Error>
    where Subject: Equatable, Subject: Sendable {
        AsyncStreamPublisher(A.stream(for: keyPath)).eraseToAnyPublisher()
    }
}

extension __AttributeProxy where A: __AttributeOptional {

    /// Default value for this property - overrides the protocol default
    public var defaultValue: A.Wrapped? { nil }
}

extension __AttributeProxy where A: __AttributeNonOptional {

    /// Default value for this property - overrides the protocol default
    public var defaultValue: A.Value { A.defaultValue }
}
