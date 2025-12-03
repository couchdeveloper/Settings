import Foundation
import Testing
import Settings

struct ProxyTestContainer1: __Settings_Container {
    static var store: UserDefaults { .standard }
    nonisolated(unsafe) static var _prefix: String = ""
    static var prefix: String { _prefix }
    
    static func setPrefix(_ newPrefix: String) {
        _prefix = newPrefix
    }
    
    static func clear() {
        store.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) }
            .forEach { store.removeObject(forKey: $0) }
    }
}

struct UserDefaultProxyTest1 {
    
    @Test 
    func testProxyNonOptional() async throws {
        ProxyTestContainer1.setPrefix("testProxyNonOptional_")
        ProxyTestContainer1.clear()
        defer { ProxyTestContainer1.clear() }

        enum Attr: __AttributeNonOptional {
            typealias Container = ProxyTestContainer1
            typealias Value = String
            static let name = "proxyString"
            static let defaultValue = "default"
            static let defaultRegistrar = __DefaultRegistrar()
        }

        let proxy = __AttributeProxy<Attr>(attributeType: Attr.self)

        #expect(proxy.wrappedValue == "default")
        #expect(proxy.key.contains("proxyString"))
        
        proxy.wrappedValue = "updated"
        #expect(Attr.read() == "updated")
        #expect(proxy.wrappedValue == "updated")

        proxy.reset()
        #expect(Attr.read() == "default")
    }
}
