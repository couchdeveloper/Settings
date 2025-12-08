import Foundation

public protocol Cancellable: Sendable {
    func cancel()
}

public protocol UserDefaultsStore: Sendable {

    associatedtype Observer: Cancellable

    func object(forKey: String) -> Any?
    func set(_ value: Any?, forKey: String)
    func removeObject(forKey: String)
    func string(forKey: String) -> String?
    func array(forKey: String) -> [Any]?
    func dictionary(forKey: String) -> [String: Any]?
    func data(forKey: String) -> Data?
    func stringArray(forKey: String) -> [String]?
    func integer(forKey: String) -> Int
    func float(forKey: String) -> Float
    func double(forKey: String) -> Double
    func bool(forKey: String) -> Bool
    func url(forKey: String) -> URL?

    func set(_ value: Int, forKey: String)
    func set(_ value: Float, forKey: String)
    func set(_ value: Double, forKey: String)
    func set(_ value: Bool, forKey: String)
    func set(_ url: URL?, forKey: String)

    func register(defaults: [String: Any])
    
    func dictionaryRepresentation() -> [String: Any]

    func observer(
        forKey: String,
        update: @escaping @Sendable (_ old: Any?, _ new: Any?) -> Void
    ) -> Observer

}
