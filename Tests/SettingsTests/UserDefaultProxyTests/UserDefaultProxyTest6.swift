import Foundation
import Settings
import Testing
import Utilities

struct ProxyTestContainer6: __Settings_Container {
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

struct UserDefaultProxyTest6 {

    @Test
    func testProxyStreamNonOptional() async throws {
        ProxyTestContainer6.setPrefix("testProxyStreamNonOptional_")
        await ProxyTestContainer6.clear()

        enum Attr: __AttributeNonOptional {
            typealias Container = ProxyTestContainer6
            typealias Value = Int
            static let name = "streamInt"
            static let defaultValue = 0
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let proxy = __AttributeProxy<Attr>(attributeType: Attr.self)

        let expectation1 = Expectation(minFulfillCount: 1)
        let expectation2 = Expectation(minFulfillCount: 1)
        let expectation3 = Expectation(minFulfillCount: 1)

        actor ValueCollector {
            var values: [Int] = []
            var callCount = 0

            func append(_ value: Int) -> Int {
                values.append(value)
                callCount += 1
                return callCount
            }

            func getValues() -> [Int] {
                values
            }
        }

        let collector = ValueCollector()

        let streamTask = Task {
            do {
                for try await value in proxy.stream {
                    let count = await collector.append(value)
                    if count == 1 {
                        expectation1.fulfill()
                    } else if count == 2 {
                        expectation2.fulfill()
                    } else if count == 3 {
                        expectation3.fulfill()
                        break
                    }
                }
            } catch {
                Issue.record("Stream threw error: \(error)")
            }
        }

        // Wait for initial default value
        try await expectation1.await(timeout: .seconds(2), clock: .continuous)

        // Small delay to ensure stream is fully ready
        try await Task.sleep(for: .milliseconds(10))

        Attr.write(value: 42)
        try await expectation2.await(timeout: .seconds(2), clock: .continuous)

        try await Task.sleep(for: .milliseconds(100))

        Attr.write(value: 99)
        try await expectation3.await(timeout: .seconds(2), clock: .continuous)

        streamTask.cancel()

        let receivedValues = await collector.getValues()
        #expect(receivedValues.count == 3)
        #expect(receivedValues[0] == 0)
        #expect(receivedValues[1] == 42)
        #expect(receivedValues[2] == 99)

        await ProxyTestContainer6.clear()
    }
}
