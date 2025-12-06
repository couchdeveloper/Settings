import Foundation
import Combine

extension __Attribute
where Value: Sendable {

    public static var publisher: AnyPublisher<Value, Error> {
        let publisher = AsyncStreamPublisher(Self.stream)
        return publisher.eraseToAnyPublisher()
    }

    public static func publisher<Subject>(
        for keyPath: KeyPath<Value, Subject>
    ) -> AnyPublisher<Subject, Error>
    where Subject: Equatable, Subject: Sendable {
        let publisher = AsyncStreamPublisher(Self.stream(for: keyPath))
        return publisher.eraseToAnyPublisher()
    }
}
