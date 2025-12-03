import Foundation
import Combine

extension __Attribute {
    public static var stream: AsyncThrowingStream<Value, Error> {
        fatalError("not yet implemented")
    }
}

extension __AttributeNonOptional where Value: Sendable {
    
    public static var stream: AsyncThrowingStream<Value, Error> {
        let (stream, continuation) = AsyncThrowingStream<Value, Error>
            .makeStream(bufferingPolicy: .unbounded)
        let observer = Container.observer(
            forKey: Self.key
        ) { oldOptAny, newOptAny in
            // Note: at the very first call of this closure, we receive
            // the initial value in `newOptAny` - which is `nil`. Only
            // immediately before the very first read, we set the default
            // value.
            
            registerDefault()

            switch newOptAny {
            case .none:
                continuation.yield(Self.defaultValue)
            case .some(let any) where any is NSNull:
                continuation.yield(Self.defaultValue)
            case .some(let obj):
                do {
                    let currentValue = try Self.decode(from: obj)
                    continuation.yield(currentValue)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        continuation.onTermination = { @Sendable _ in
            // `observer`'s life-cycle will be bound to the
            // stream's continuation.
            observer.cancel()
        }
        return stream
    }
}

extension __AttributeOptional where Value: Sendable, Value: ExpressibleByNilLiteral {

    public static var stream: AsyncThrowingStream<Value, Error> {
        let (stream, continuation) = AsyncThrowingStream<Value, Error>
            .makeStream(bufferingPolicy: .unbounded)
        let observer = Container.observer(
            forKey: Self.key
        ) { oldOptAny, newOptAny in
            // Note: at the very first call of this closure, we receive
            // the initial value in `newOptAny` - which is `nil`. Only
            // immediately before the very first read, we set the default
            // value.
            switch newOptAny {
            case .none:
                continuation.yield(nil)
            case .some(let any) where any is NSNull:
                continuation.yield(nil)
            case .some(let obj):
                do {
                    let currentValue = try Self.decode(from: obj)
                    continuation.yield(currentValue)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        continuation.onTermination = { @Sendable _ in
            // `observer`'s life-cycle will be bound to the
            // stream's continuation.
            observer.cancel()
        }
        return stream
    }
}

extension __Attribute {

    public static func stream<Subject>(
        for keyPath: KeyPath<Value, Subject>
    ) -> AsyncThrowingStream<Subject, Error>
    where Subject: Equatable, Subject: Sendable {
        AsyncThrowingStream { continuation in
            var lastSubject: Subject? = nil
            // It should be safe to use sendableKeyPath, since we operate on a
            // a copy of a value allocated on the stack.
            let keyPath = unsafeSendableKeyPath(keyPath)
            Task {
                let valueStream = Self.stream
                for try await value in valueStream {
                    if let optional = value as? AnyOptional, optional.isNil {
                        assertionFailure(
                            "Attempted to project a keyPath from nil optional value. Use an optional-safe keyPath (e.g., \\Value?.property)"
                        )
                    }
                    let subject = value[keyPath: keyPath]
                    if lastSubject != subject {
                        lastSubject = subject
                        continuation.yield(subject)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = {
                _ in /* No-op: inner stream handles observer clean-up */
            }
        }
    }
}


// MARK: - Marker protocol _CustomCodableValue

/// Marker protocol for custom Codable types (excludes primitive types like Bool, Int, String, etc.)
public protocol _CustomCodableValue: Codable {}

// Make common collection types conform to the marker protocol
extension Array: _CustomCodableValue where Element: Codable {}
extension Dictionary: _CustomCodableValue where Key: Codable, Value: Codable {}
extension Set: _CustomCodableValue where Element: Codable {}

public protocol OptionalCustomCodableValue<Wrapped> {
    associatedtype Wrapped: _CustomCodableValue

    init(wrapped: Wrapped)
}

extension Optional: OptionalCustomCodableValue
where Wrapped: _CustomCodableValue {
    public init(wrapped: Wrapped) {
        self = Optional(wrapped)
    }
}

/// Private protocol to detect if a value is an Optional and if it is nil.
private protocol AnyOptional {
    var isNil: Bool { get }
}
extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}

// MARK: - Fix KeyPath Sendability

typealias _SendableKeyPath<Root, Value> = any KeyPath<Root, Value> & Sendable
typealias _SendableWritableKeyPath<Root, Value> = any WritableKeyPath<
    Root, Value
> & Sendable

/// > Warning: If your key path is not sendable (like if it is a subscript key path that captures
/// non-sendable data), then this will crash.
func unsafeSendableKeyPath<Root, Value>(
    _ keyPath: KeyPath<Root, Value>
) -> _SendableKeyPath<Root, Value> {
    unsafeBitCast(keyPath, to: _SendableKeyPath<Root, Value>.self)
}

/// > Warning: If your key path is not sendable (like if it is a subscript key path that captures
/// non-sendable data), then this will crash.
func unsafeSendableKeyPath<Root, Value>(
    _ keyPath: WritableKeyPath<Root, Value>
) -> _SendableWritableKeyPath<Root, Value> {
    unsafeBitCast(keyPath, to: _SendableWritableKeyPath<Root, Value>.self)
}
