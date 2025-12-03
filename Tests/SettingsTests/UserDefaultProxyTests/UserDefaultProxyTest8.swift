import Foundation
import Testing
import Settings
import Combine
import Utilities

struct ProxyTestContainer8: __Settings_Container {
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

struct UserDefaultProxyTest8 {
    
    @Test 
    func testProxyPublisherCustomType() async throws {
        ProxyTestContainer8.setPrefix("testProxyPublisherCustomType_")
        await ProxyTestContainer8.clear()
        
        struct User: Codable, Equatable, Sendable {
            var name: String
            var age: Int
        }

        enum AttrUser: __AttributeNonOptional {
            typealias Container = ProxyTestContainer8
            typealias Value = User
            static let name = "user"
            static let defaultValue = User(name: "Guest", age: 0)
            static let defaultRegistrar = __DefaultRegistrar()
            static let encoder = JSONEncoder()
            static let decoder = JSONDecoder()
        }

        let proxy = __AttributeProxy<AttrUser>(attributeType: AttrUser.self)
        
        actor ValueCollector {
            var values: [User] = []
            var started = false
            var callCount = 0
            
            func start() {
                started = true
            }
            
            func append(_ value: User) -> Int {
                if started {
                    values.append(value)
                    callCount += 1
                }
                return callCount
            }
            
            func getValues() -> [User] {
                values
            }
        }
        
        let collector = ValueCollector()
        let expectation1 = Expectation(minFulfillCount: 1)
        let expectation2 = Expectation(minFulfillCount: 1)
        
        let cancellable = proxy.publisher
            .dropFirst() // Skip initial value
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
        
        AttrUser.write(value: User(name: "Alice", age: 30))
        try await expectation1.await(timeout: .seconds(2), clock: .continuous)
        
        AttrUser.write(value: User(name: "Bob", age: 25))
        try await expectation2.await(timeout: .seconds(2), clock: .continuous)
        
        let receivedValues = await collector.getValues()
        #expect(receivedValues.count == 2)
        #expect(receivedValues[0] == User(name: "Alice", age: 30))
        #expect(receivedValues[1] == User(name: "Bob", age: 25))
        
        cancellable.cancel()
        await ProxyTestContainer8.clear()
    }
}
