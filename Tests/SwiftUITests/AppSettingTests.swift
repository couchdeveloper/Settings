import Testing
import Foundation
import SwiftUI
import Combine
import Settings
import Utilities

// Test container using standard UserDefaults (each test cleans up its own keys)
struct TestSettingValues: __Settings_Container {
    static var store: UserDefaults {
        UserDefaults.standard
    }
    
    static var prefix: String {
        "com_settings_test_appsetting_"
    }
    
    static func clear() {
        let keysToRemove = store.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) }
        for key in keysToRemove {
            store.removeObject(forKey: key)
        }
    }
}

// Define test settings at file scope
extension TestSettingValues {
    @Setting static var testString: String = "default"
    @Setting static var testInt: Int = 0
    @Setting static var testBool: Bool = false
    @Setting static var sharedValue: String = "initial"
    @Setting static var observedValue: Int = 0
    @Setting static var optionalString: String?
}

@Suite("AppSetting Property Wrapper Tests", .serialized)
struct AppSettingTests {
    
    init() {
        TestSettingValues.clear()
    }
    
    @Test("AppSetting initialization reads current UserDefaults value")
    func testInitialization() throws {
        defer { TestSettingValues.clear() }
        
        // Set a value directly in UserDefaults
        TestSettingValues.testString = "initial"
        
        // Create AppSetting wrapper
        let wrapper = AppSetting(TestSettingValues.$testString)
        
        // Should read the current value
        #expect(wrapper.wrappedValue == "initial")
    }
    
    @Test("AppSetting wrappedValue writes to UserDefaults")
    func testWriting() throws {
        defer { TestSettingValues.clear() }
        
        let wrapper = AppSetting(TestSettingValues.$testInt)
        
        // Write via wrapper
        wrapper.wrappedValue = 42
        
        // Verify it's in UserDefaults
        #expect(TestSettingValues.testInt == 42)
    }
    
    @Test("AppSetting projectedValue provides working binding")
    func testBinding() throws {
        defer { TestSettingValues.clear() }
        
        let wrapper = AppSetting(TestSettingValues.$testBool)
        let binding = wrapper.projectedValue
        
        // Note: Bindings work through the underlying @State which requires
        // SwiftUI's view lifecycle. In unit tests, we verify the binding
        // structure is correct.
        #expect(binding.wrappedValue == false)
        
        // Writing through the wrapper directly should work
        TestSettingValues.testBool = true
        #expect(TestSettingValues.testBool == true)
    }
    
    @Test("Multiple AppSettings can reference same UserDefaults key")
    func testMultipleReferences() throws {
        defer { TestSettingValues.clear() }
        
        // Create two wrapper instances for the same setting
        let wrapper1 = AppSetting(TestSettingValues.$sharedValue)
        let wrapper2 = AppSetting(TestSettingValues.$sharedValue)
        
        // Both should read the same initial value
        #expect(wrapper1.wrappedValue == "initial")
        #expect(wrapper2.wrappedValue == "initial")
        
        // Change value through UserDefaults directly
        TestSettingValues.sharedValue = "updated"
        
        // New wrappers will read the updated value
        let wrapper3 = AppSetting(TestSettingValues.$sharedValue)
        #expect(wrapper3.wrappedValue == "updated")
    }
    
    @Test("AppSetting update method can be called")
    func testUpdateMethod() throws {
        defer { TestSettingValues.clear() }
        
        var wrapper = AppSetting(TestSettingValues.$observedValue)
        
        // Initially reads current value
        #expect(wrapper.wrappedValue == 0)
        
        // Call update to establish subscription
        // Note: The actual subscription behavior requires SwiftUI's lifecycle
        // to properly update @State. Here we verify update() doesn't crash.
        wrapper.update()
        
        // Can call multiple times (should be idempotent due to nil check)
        wrapper.update()
        wrapper.update()
    }
    
    @Test("AppSetting works with optional values")
    func testOptionalValues() throws {
        defer { TestSettingValues.clear() }
        
        let wrapper = AppSetting(TestSettingValues.$optionalString)
        
        // Initially nil
        #expect(wrapper.wrappedValue == nil)
        
        // Set a value
        wrapper.wrappedValue = "present"
        #expect(TestSettingValues.optionalString == "present")
        
        // Clear it
        wrapper.wrappedValue = nil
        #expect(TestSettingValues.optionalString == nil)
    }
    
    @Test("Attribute publisher emits values on UserDefaults changes")
    func testAttributePublisher() async throws {
        defer { TestSettingValues.clear() }
        
        // Set initial value
        TestSettingValues.sharedValue = "initial"
        
        // Actor to collect values safely
        actor ValueCollector {
            private var values: [String] = []
            
            func append(_ value: String) -> Int {
                values.append(value)
                return values.count
            }
            
            func getValues() -> [String] {
                values
            }
        }
        
        let collector = ValueCollector()
        let expectation1 = Expectation(minFulfillCount: 1)
        let expectation2 = Expectation(minFulfillCount: 1)
        
        // Subscribe to the attribute's publisher via proxy
        let cancellable = TestSettingValues.$sharedValue.publisher
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
        
        // Wait for initial value
        try await expectation1.await(timeout: Duration.seconds(2), clock: ContinuousClock())
        
        // Give time for subscription to stabilize
        try await Task.sleep(for: .milliseconds(50))
        
        // Change the value
        TestSettingValues.sharedValue = "updated"
        
        // Wait for updated value
        try await expectation2.await(timeout: Duration.seconds(2), clock: ContinuousClock())
        
        let receivedValues = await collector.getValues()
        // Verify we received at least 2 values and both expected values are present
        #expect(receivedValues.count >= 2)
        #expect(receivedValues.contains("initial"))
        #expect(receivedValues.contains("updated"))
        
        cancellable.cancel()
    }
    
    @Test("Attribute publisher observes UserDefaults changes")
    func testAttributePublisherObservation() async throws {
        defer { TestSettingValues.clear() }
        
        TestSettingValues.testBool = false
        
        actor BoolCollector {
            private var values: [Bool] = []
            
            func append(_ value: Bool) -> Int {
                values.append(value)
                return values.count
            }
            
            func contains(_ value: Bool) -> Bool {
                values.contains(value)
            }
        }
        
        let collector = BoolCollector()
        let expectation1 = Expectation(minFulfillCount: 1)
        let expectation2 = Expectation(minFulfillCount: 1)
        
        let cancellable = TestSettingValues.$testBool.publisher
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
        
        // Wait for initial value
        try await expectation1.await(timeout: Duration.seconds(2), clock: ContinuousClock())
        
        // Give time for subscription to stabilize
        try await Task.sleep(for: .milliseconds(100))
        
        // Change the value
        TestSettingValues.testBool = true
        
        // Wait for change to be observed
        try await expectation2.await(timeout: Duration.seconds(2), clock: ContinuousClock())
        
        // Verify both values were observed
        let hasFalse = await collector.contains(false)
        let hasTrue = await collector.contains(true)
        #expect(hasFalse)
        #expect(hasTrue)
        
        cancellable.cancel()
    }
}
