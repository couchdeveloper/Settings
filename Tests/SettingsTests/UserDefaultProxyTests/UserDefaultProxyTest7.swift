import Foundation
import Testing
import Settings
import Utilities

struct ProxyTestContainer7: __Settings_Container {
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

struct UserDefaultProxyTest7 {
    
    @Test 
    func testProxyStreamOptional() async throws {
        ProxyTestContainer7.setPrefix("testProxyStreamOptional_")
        await ProxyTestContainer7.clear()
        
        enum AttrOpt: __AttributeOptional {
            typealias Container = ProxyTestContainer7
            typealias Value = Bool?
            typealias Wrapped = Bool
            static let name = "streamBoolOpt"
        }

        let proxy = __AttributeProxy<AttrOpt>(attributeType: AttrOpt.self)
        
        actor ValueCollector {
            var values: [Bool?] = []
            var callCount = 0
            
            func append(_ value: Bool?) -> Int {
                values.append(value)
                callCount += 1
                return callCount
            }
            
            func getValues() -> [Bool?] {
                values
            }
        }
        
        let collector = ValueCollector()
        let expectation1 = Expectation(minFulfillCount: 1)
        let expectation2 = Expectation(minFulfillCount: 1)
        let expectation3 = Expectation(minFulfillCount: 1)
        
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
        
        try await expectation1.await(timeout: .seconds(2), clock: .continuous)
        
        AttrOpt.write(value: true)
        try await expectation2.await(timeout: .seconds(2), clock: .continuous)
        
        AttrOpt.write(value: nil)
        try await expectation3.await(timeout: .seconds(2), clock: .continuous)
        
        streamTask.cancel()
        
        let receivedValues = await collector.getValues()
        #expect(receivedValues.count == 3)
        #expect(receivedValues[0] == nil)
        #expect(receivedValues[1] == true)
        #expect(receivedValues[2] == nil)
        
        await ProxyTestContainer7.clear()
    }
}
