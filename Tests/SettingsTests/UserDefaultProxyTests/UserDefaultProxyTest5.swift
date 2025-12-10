import Combine
import Foundation
import Settings
import Testing
import Utilities

struct ProxyTestContainer5: __Settings_Container {
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

struct UserDefaultProxyTest5 {

    @Test
    func testProxyPublisherArray() async throws {
        ProxyTestContainer5.setPrefix("testProxyPublisherArray_")
        await ProxyTestContainer5.clear()

        enum AttrArray: __AttributeNonOptional {
            typealias Container = ProxyTestContainer5
            typealias Value = [String]
            static let name = "publisherArray"
            static let defaultValue: [String] = []
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let proxy = __AttributeProxy<AttrArray>(attributeType: AttrArray.self)

        actor ValueCollector {
            var values: [[String]] = []
            var started = false
            var callCount = 0

            func start() {
                started = true
            }

            func append(_ value: [String]) -> Int {
                if started {
                    values.append(value)
                    callCount += 1
                }
                return callCount
            }

            func getValues() -> [[String]] {
                values
            }
        }

        let collector = ValueCollector()
        let expectation1 = Expectation(minFulfillCount: 1)
        let expectation2 = Expectation(minFulfillCount: 1)

        let cancellable = proxy.publisher
            .dropFirst()  // Skip initial value
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { value in
                    Task {
                        let count = await collector.append(value)
                        if count == 1 {
                            expectation1.fulfill()
                        } else if count == 2 {
                            expectation2.fulfill()
                        }
                    }
                }
            )

        // Give publisher time to start listening
        try await Task.sleep(for: .milliseconds(100))
        await collector.start()

        AttrArray.write(value: ["one", "two"])
        try await expectation1.await(timeout: .seconds(2), clock: .continuous)

        AttrArray.write(value: ["one", "two", "three"])
        try await expectation2.await(timeout: .seconds(2), clock: .continuous)

        let receivedValues = await collector.getValues()
        #expect(receivedValues.count == 2)
        #expect(receivedValues[0] == ["one", "two"])
        #expect(receivedValues[1] == ["one", "two", "three"])

        cancellable.cancel()
        await ProxyTestContainer5.clear()
    }
}
