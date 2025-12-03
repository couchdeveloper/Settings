import Atomics

public struct __DefaultRegistrar: @unchecked Sendable {
    
    public init() {}

    // Note: An UnsafeAtomic value will be allocated for each distinct
    // UserDefault value and will never be released.
    private let didRegister = UnsafeAtomic<Bool>.create(false)

    func registerDefaultIfNeeded<Container>(
        container: Container.Type, 
        key: String, 
        encodedDefaultValue: @autoclosure () throws -> Any
    ) where Container: __Settings_Container {
        // Atomically set the flag to true if it was false
        let didSet = didRegister.compareExchange(
            expected: false,
            desired: true,
            ordering: .acquiring
        ).exchanged
        guard didSet else { return }
        
        // Only encode the default value if we actually need to register it
        do {
            let encoded = try encodedDefaultValue()
            Container.registerDefault(key: key, defaultValue: encoded)
        } catch {
            fatalError("Could not encode default value: \(error)")
        }
    }
}
