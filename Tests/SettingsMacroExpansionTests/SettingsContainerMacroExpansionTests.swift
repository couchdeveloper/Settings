import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import SettingsMacros

final class UserDefaultsContainerMacroExpansionTests: XCTestCase {

    // MARK: - Basic UserDefaults Container Macro Tests

    func testUserDefaultsContainerMacroWithNoArguments() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings struct DefaultSettings {
                }
                """,
                expandedSource: """
                    struct DefaultSettings {

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = ""
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension DefaultSettings: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testUserDefaultsContainerMacroWithEmptyParameters() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings()
                struct AppSettings {
                }
                """,
                expandedSource: """
                    struct AppSettings {

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = ""
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension AppSettings: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testUserDefaultsContainerMacroWithEmptyPrefix() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings("")
                struct MinimalSettings {
                }
                """,
                expandedSource: """
                    struct MinimalSettings {

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = ""
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension MinimalSettings: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testUserDefaultsContainerMacroWithLabeledPrefix() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings(prefix: "app_")
                struct AppSettings {
                }
                """,
                expandedSource: """
                    struct AppSettings {

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = "app_"
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension AppSettings: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testUserDefaultsContainerMacroWithUnlabeledPrefix() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings("com_myapp_")
                struct AppSettings {
                }
                """,
                expandedSource: """
                    struct AppSettings {

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = "com_myapp_"
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension AppSettings: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testUserDefaultsContainerMacroWithSuiteName() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings(suiteName: "com.example.suite")
                struct AppSettings {
                }
                """,
                expandedSource: """
                    struct AppSettings {

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = ""
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension AppSettings: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testUserDefaultsContainerMacroWithLabeledPrefixAndSuiteName() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings(prefix: "app_", suiteName: "com.example.suite")
                struct AppSettings {
                }
                """,
                expandedSource: """
                    struct AppSettings {

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = "app_"
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension AppSettings: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    // MARK: - Container Type Support Tests

    func testUserDefaultsContainerMacroWithClass() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings("app_")
                class AppConfiguration {
                }
                """,
                expandedSource: """
                    class AppConfiguration {

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = "app_"
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension AppConfiguration: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testUserDefaultsContainerMacroWithEnum() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings("config_")
                enum ConfigSettings {
                }
                """,
                expandedSource: """
                    enum ConfigSettings {

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = "config_"
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension ConfigSettings: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testUserDefaultsContainerMacroWithActor() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings("actor_")
                actor ActorSettings {
                }
                """,
                expandedSource: """
                    actor ActorSettings {

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = "actor_"
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension ActorSettings: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testUserDefaultsContainerMacroRejectsDotPrefix() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings("invalid.prefix")
                struct InvalidPrefixSettings {}
                """,
                expandedSource: """
                    struct InvalidPrefixSettings {}

                    extension InvalidPrefixSettings: __Settings_Container {
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message:
                            "Invalid prefix: invalid.prefix. The prefix is not KVC compliant. It must not contain dots (\".\").",
                        line: 1,
                        column: 1
                    )
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    // MARK: - Integration Tests with UserDefault

    func testUserDefaultsContainerWithUserDefaultProperties() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings("app_")
                struct AppSettings {
                    @Setting var username: String = "anonymous"
                }
                """,
                expandedSource: """
                    struct AppSettings {
                        var username: String {
                            get {
                                return __Attribute_AppSettings_username.read()
                            }
                            set {
                                __Attribute_AppSettings_username.write(value: newValue)
                            }
                        }

                        public enum __Attribute_AppSettings_username: __AttributeNonOptional {
                            public typealias Container = AppSettings
                            public typealias Value = String
                            public static let name = "username"
                            public static let defaultValue: String = "anonymous"
                            public static let defaultRegistrar = __DefaultRegistrar()
                        }

                        public var $username: __AttributeProxy<__Attribute_AppSettings_username> {
                            return __AttributeProxy(attributeType: __Attribute_AppSettings_username.self)
                        }

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = "app_"
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension AppSettings: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testUserDefaultsContainerWithCustomKeyNames() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings("settings_")
                struct UserPreferences {
                    @Setting(name: "user_name") var username: String = "guest"
                    @Setting var theme: String = "light"
                }
                """,
                expandedSource: """
                    struct UserPreferences {
                        var username: String {
                            get {
                                return __Attribute_UserPreferences_username.read()
                            }
                            set {
                                __Attribute_UserPreferences_username.write(value: newValue)
                            }
                        }

                        public enum __Attribute_UserPreferences_username: __AttributeNonOptional {
                            public typealias Container = UserPreferences
                            public typealias Value = String
                            public static let name = "user_name"
                            public static let defaultValue: String = "guest"
                            public static let defaultRegistrar = __DefaultRegistrar()
                        }

                        public var $username: __AttributeProxy<__Attribute_UserPreferences_username> {
                            return __AttributeProxy(attributeType: __Attribute_UserPreferences_username.self)
                        }
                        var theme: String {
                            get {
                                return __Attribute_UserPreferences_theme.read()
                            }
                            set {
                                __Attribute_UserPreferences_theme.write(value: newValue)
                            }
                        }

                        public enum __Attribute_UserPreferences_theme: __AttributeNonOptional {
                            public typealias Container = UserPreferences
                            public typealias Value = String
                            public static let name = "theme"
                            public static let defaultValue: String = "light"
                            public static let defaultRegistrar = __DefaultRegistrar()
                        }

                        public var $theme: __AttributeProxy<__Attribute_UserPreferences_theme> {
                            return __AttributeProxy(attributeType: __Attribute_UserPreferences_theme.self)
                        }

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = "settings_"
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension UserPreferences: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testUserDefaultsContainerWithSuiteNameAndUserDefaults() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings(prefix: "game_", suiteName: "com.example.gamedata")
                struct GameSettings {
                    @Setting var playerName: String = "Player1"
                    @Setting var highScore: Int = 0
                }
                """,
                expandedSource: """
                    struct GameSettings {
                        var playerName: String {
                            get {
                                return __Attribute_GameSettings_playerName.read()
                            }
                            set {
                                __Attribute_GameSettings_playerName.write(value: newValue)
                            }
                        }

                        public enum __Attribute_GameSettings_playerName: __AttributeNonOptional {
                            public typealias Container = GameSettings
                            public typealias Value = String
                            public static let name = "playerName"
                            public static let defaultValue: String = "Player1"
                            public static let defaultRegistrar = __DefaultRegistrar()
                        }

                        public var $playerName: __AttributeProxy<__Attribute_GameSettings_playerName> {
                            return __AttributeProxy(attributeType: __Attribute_GameSettings_playerName.self)
                        }
                        var highScore: Int {
                            get {
                                return __Attribute_GameSettings_highScore.read()
                            }
                            set {
                                __Attribute_GameSettings_highScore.write(value: newValue)
                            }
                        }

                        public enum __Attribute_GameSettings_highScore: __AttributeNonOptional {
                            public typealias Container = GameSettings
                            public typealias Value = Int
                            public static let name = "highScore"
                            public static let defaultValue: Int = 0
                            public static let defaultRegistrar = __DefaultRegistrar()
                        }

                        public var $highScore: __AttributeProxy<__Attribute_GameSettings_highScore> {
                            return __AttributeProxy(attributeType: __Attribute_GameSettings_highScore.self)
                        }

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = "game_"
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension GameSettings: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    // MARK: - Edge Cases and Error Conditions

    func testUserDefaultsContainerWithExistingConformance() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                @Settings("existing_")
                struct ExistingContainer: __Settings_Container {
                    static let someProperty = "value"
                }
                """,
                expandedSource: """
                    struct ExistingContainer: __Settings_Container {
                        static let someProperty = "value"

                        struct Config {
                            var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                            var prefix: String = "existing_"
                        }

                        private static let _config = OSAllocatedUnfairLock(initialState: Config())

                        public internal(set) static var store: any UserDefaultsStore {
                            get {
                                _config.withLock { config in
                                    config.store
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.store = newValue
                                }
                            }
                        }

                        public static var prefix: String {
                            get {
                                _config.withLock { config in
                                    config.prefix
                                }
                            }
                            set {
                                _config.withLock { config in
                                    config.prefix = newValue.replacing(".", with: "_")
                                }
                            }
                        }
                    }

                    extension ExistingContainer: __Settings_Container {
                    }
                    """,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    // MARK: - Test Configuration

    private let testMacros: [String: Macro.Type] = [
        "Settings": SettingsMacro.self,
        "Setting": SettingMacro.self,
    ]
}
