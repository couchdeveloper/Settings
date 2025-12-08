import Settings
import SettingsMock
import Foundation
import Observation
import Combine

// protocol ConstString {
//     static var value: String { get }
// }
//
// struct Container<Prefix: ConstString>: __Container {
//     static var store: any UserDefaultsStore { Foundation.UserDefaults.standard }
//     static var prefix: String { Prefix.value }
//
//     static func clear() {
//         for key in keys {
//             store.removeObject(forKey: key)
//         }
//     }
//
//     static var keys: [String] {
//         Array(store.dictionaryRepresentation().keys).filter {
//             $0.hasPrefix(prefix)
//         }
//     }
// }
//
// func test() throws {
//     enum Prefix: ConstString {
//         static let value = "com_UserDefaultsClient_UserDefaultAttributeCodingTests_testBool_"
//     }
//     typealias C = Container<Prefix>
//
//     enum Attr: __AttributeNonOptional {
//         typealias Container = C
//         typealias Value = Bool
//         static let name = "bool"
//         static let defaultValue = false
//     }
//     let obj = try Attr.encode(true)
//     print(obj)
//     let value = try Attr.decode(from: obj)
//     print(value)
// }
//
// print("Hello UserDefaults!")
// try test()

@Settings(prefix: "app_") struct Settings {
    @Setting var setting: String = "default"
}


@Settings struct AppSettings {}
extension AppSettings { enum UserSettings {
    @Setting var setting: String = "default"
    @Setting var theme: String?
} }

@Settings(prefix: "app_") struct AppSettings1 {}
extension AppSettings1 { enum UserSettings {
    @Setting var setting: String = "default"
    @Setting var theme: String?
} }


@Settings(prefix: "com_example_MyApp_")
struct AppSettings2 {
    @Setting static var username: String = "Guest"  // Default value "Guest"
    @Setting(name: "colorScheme") static var theme: String = "light" //  key = "colorScheme"
    @Setting static var apiKey: String?  // Optionals don't have default values
    @Setting(name: "value") var primitive: Int = 42
}

extension AppSettings2 { enum Profiles {
    struct UserProfile: Equatable, Codable, Identifiable {
        var id: UUID
        var user: String
        var image: URL?
    }

    @Setting(encoding: .json)
    static var userProfile: UserProfile? //
    
    @Setting var setting = "abc"
}}

final class UserProfileObserver {
    var subscriptions: Array<AnyCancellable> = []
    
    init() {
        AppSettings2.Profiles.$userProfile.publisher.sink(
            receiveCompletion: { error in
                print(error)
            }, receiveValue: { value in
                switch value {
                case .none:
                    print("No user profile")
                case .some(let profile):
                    print("New user profile: \(profile)")
                }
            }
        ).store(in: &subscriptions)
    }
}


func main1() async throws {
    // let userProfileObserver = UserProfileObserver()
    
    AppSettings2.Profiles.userProfile = .init(id: UUID(), user: "John Appleseed", image: nil)
    print(AppSettings2.theme) // "light"
    print(AppSettings2.Profiles.$userProfile.key)

    try await Task.sleep(for: .milliseconds(1000))
}


import Observation

@Observable
final class ViewModel {
    @Settings struct Settings {
        @Setting var hasSeenOnboarding = false
    }
    
    var settings = Settings()
}


try await main1()

// MARK: - App
import SwiftUI

extension AppSettingValues {
    @Setting var user: String?
    @Setting var theme: String = "default"
}

// @main
struct SettingsView: View {
    @Environment(\.userDefaultsStore) var settings

    var body: some View {
        Text(verbatim: "\(settings.dictionaryRepresentation())")
    }
}

struct ProductionApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Test")
            SettingsView()
        }
        .environment(\.userDefaultsStore, UserDefaultsStoreMock())
    }
}

// #Preview {
//     SettingsView()
//         .environment(\.userDefaultsStore, UserDefaultsStoreMock(store: ["user": "John"]))
// }
