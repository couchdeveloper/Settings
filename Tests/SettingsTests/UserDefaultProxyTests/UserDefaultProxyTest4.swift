import Foundation
import Testing
import Settings
import Combine
import Utilities

struct ProxyTestContainer4: __Settings_Container {
    static var store: UserDefaults { .standard }
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

struct UserDefaultProxyTest4 {
    
    @Test 
    func testProxyPublisherOptional() async throws {
        ProxyTestContainer4.setPrefix("testProxyPublisherOptional_")
        await ProxyTestContainer4.clear()

        enum AttrOpt: __AttributeOptional {
            typealias Container = ProxyTestContainer4
            typealias Value = String?
            typealias Wrapped = String
            static let name = "publisherStringOpt"
        }

        let proxy = __AttributeProxy<AttrOpt>(attributeType: AttrOpt.self)
        
        actor ValueCollector {
            var values: [String?] = []
            var callCount = 0
            
            func append(_ value: String?) -> Int {
                values.append(value)
                callCount += 1
                return callCount
            }
            
            func getValues() -> [String?] {
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
        
        AttrOpt.write(value: "exists")
        try await expectation2.await(timeout: .seconds(2), clock: .continuous)
        
        AttrOpt.write(value: nil)
        try await expectation3.await(timeout: .seconds(2), clock: .continuous)
        
        let receivedValues = await collector.getValues()
        #expect(receivedValues.count == 3)
        #expect(receivedValues[0] == nil)
        #expect(receivedValues[1] == "exists")
        #expect(receivedValues[2] == nil)
        
        cancellable.cancel()
        await ProxyTestContainer4.clear()
    }
}
