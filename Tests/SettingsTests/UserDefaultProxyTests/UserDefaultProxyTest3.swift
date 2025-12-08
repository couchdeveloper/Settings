import Foundation
import Testing
import Settings
import Combine
import Utilities

struct ProxyTestContainer3: __Settings_Container {
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
        // Give KVO time to propagate removals
        try? await Task.sleep(for: .milliseconds(50))
    }
}

struct UserDefaultProxyTest3 {
    
    @Test 
    func testProxyPublisherNonOptional() async throws {
        ProxyTestContainer3.setPrefix("testProxyPublisherNonOptional_")
        await ProxyTestContainer3.clear()
        
        enum Attr: __AttributeNonOptional {
            typealias Container = ProxyTestContainer3
            typealias Value = String
            static let name = "publisherString"
            static let defaultValue = "initial"
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let proxy = __AttributeProxy<Attr>(attributeType: Attr.self)
        
        actor ValueCollector {
            var values: [String] = []
            var callCount = 0
            
            func append(_ value: String) -> Int {
                values.append(value)
                callCount += 1
                return callCount
            }
            
            func getValues() -> [String] {
                values
            }
        }
        
        let collector = ValueCollector()
        let expectation1 = Expectation(minFulfillCount: 1)
        let expectation2 = Expectation(minFulfillCount: 1)
        let expectation3 = Expectation(minFulfillCount: 1)
        
        let cancellable = proxy.publisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { value in
                    Task {
                        let count = await collector.append(value)
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
        
        Attr.write(value: "first")
        try await expectation2.await(timeout: .seconds(2), clock: .continuous)
        
        Attr.write(value: "second")
        try await expectation3.await(timeout: .seconds(2), clock: .continuous)
        
        let receivedValues = await collector.getValues()
        #expect(receivedValues.count == 3)
        #expect(receivedValues[0] == "initial")
        #expect(receivedValues[1] == "first")
        #expect(receivedValues[2] == "second")
        
        cancellable.cancel()
        await ProxyTestContainer3.clear()
    }
}
