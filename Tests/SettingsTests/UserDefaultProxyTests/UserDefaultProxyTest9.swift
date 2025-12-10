import Combine
import Foundation
import Settings
import Testing
import Utilities

struct ProxyTestContainer9: __Settings_Container {
    static var store: any UserDefaultsStore { Foundation.UserDefaults.standard }
    nonisolated(unsafe) static var _prefix: String = ""
    static var prefix: String { _prefix }

    static func setPrefix(_ newPrefix: String) {
        _prefix = newPrefix
    }

    static func clear() async {
        let keysToRemove = store.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) }
        keysToRemove.forEach { store.removeObject(forKey: $0) }
        try? await Task.sleep(for: .milliseconds(50))
    }
}

struct UserDefaultProxyTest9 {

    @Test
    func testProxyPublisherCustomTypeKeyPath() async throws {
        ProxyTestContainer9.setPrefix("testProxyPublisherCustomTypeKeyPath_")
        await ProxyTestContainer9.clear()

        struct User: Codable, Equatable, Sendable {
            var name: String
            var age: Int
        }

        enum AttrUser: __AttributeNonOptional {
            typealias Container = ProxyTestContainer9
            typealias Value = User
            static let name = "userKeyPath"
            static let defaultValue = User(name: "Default", age: 0)
            static let defaultRegistrar = __DefaultRegistrar()
            static let encoder = JSONEncoder()
            static let decoder = JSONDecoder()
        }

        let proxy = __AttributeProxy<AttrUser>(attributeType: AttrUser.self)

        actor ValueCollector {
            var names: [String] = []
            var callCount = 0

            func append(_ name: String) -> Int {
                names.append(name)
                callCount += 1
                return callCount
            }

            func getNames() -> [String] {
                names
            }
        }

        let collector = ValueCollector()
        let expectation1 = Expectation(minFulfillCount: 1)
        let expectation2 = Expectation(minFulfillCount: 1)
        let expectation3 = Expectation(minFulfillCount: 1)

        let cancellable = proxy.publisher(for: \.name)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { name in
                    Task {
                        let count = await collector.append(name)
                        if count == 1 {
                            expectation1.fulfill()
                        } else if count == 2 {
                            expectation2.fulfill()
                        } else if count == 3 {
                            expectation3.fulfill()
                        }
                    }
                }
            )

        try await expectation1.await(timeout: .seconds(2), clock: .continuous)

        AttrUser.write(value: User(name: "Charlie", age: 35))
        try await expectation2.await(timeout: .seconds(2), clock: .continuous)

        // Age change should not emit since we're only observing name
        AttrUser.write(value: User(name: "Charlie", age: 40))
        try await Task.sleep(for: .milliseconds(50))

        AttrUser.write(value: User(name: "Diana", age: 28))
        try await expectation3.await(timeout: .seconds(2), clock: .continuous)

        let receivedNames = await collector.getNames()
        #expect(receivedNames.count == 3)
        #expect(receivedNames[0] == "Default")
        #expect(receivedNames[1] == "Charlie")
        #expect(receivedNames[2] == "Diana")

        cancellable.cancel()
        await ProxyTestContainer9.clear()
    }
}
