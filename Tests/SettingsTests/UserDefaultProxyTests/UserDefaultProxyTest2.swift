import Foundation
import Testing
import Settings

struct ProxyTestContainer2: __Settings_Container {
    static var store: any UserDefaultsStore { Foundation.UserDefaults.standard }
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

struct UserDefaultProxyTest2 {
    
    @Test 
    func testProxyOptional() async throws {
        ProxyTestContainer2.setPrefix("testProxyOptional_")
        ProxyTestContainer2.clear()
        defer { ProxyTestContainer2.clear() }

        enum AttrOpt: __AttributeOptional {
            typealias Container = ProxyTestContainer2
            typealias Value = String?
            typealias Wrapped = String
            static let name = "proxyStringOpt"
        }

        let proxy = __AttributeProxy<AttrOpt>(attributeType: AttrOpt.self)

        #expect(proxy.wrappedValue == nil)
        
        proxy.wrappedValue = "hello"
        #expect(AttrOpt.read() == "hello")
        #expect(proxy.wrappedValue == "hello")

        proxy.reset()
        #expect(AttrOpt.read() == nil)
    }
}
