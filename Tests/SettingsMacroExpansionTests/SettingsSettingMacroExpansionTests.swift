import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import SettingsMacros

final class SettingsSettingMacroExpansionTests: XCTestCase {
    struct Case {
        init(type: String, initializer: String, description: String) {
            self.type = type
            self.initialValue = initializer
            self.description = description
        }

        init(optionalType: String, description: String) {
            self.type = "\(optionalType)?"
            self.initialValue = ""
            self.description = description
        }

        var type: String
        var initialValue: String
        var description: String
    }

    private let testMacros: [String: Macro.Type] = [
        "Setting": SettingMacro.self,
        "Settings": SettingsMacro.self,
    ]

    func testBool00() throws {
        #if canImport(SettingsMacros)
            let input = """
                @Settings struct AppSettings {
                    @Setting var setting: Bool = true
                }
                """

            let expected = """
                struct AppSettings {
                    var setting: Bool {
                        get {
                            return __Attribute_AppSettings_setting.read()
                        }
                        set {
                            __Attribute_AppSettings_setting.write(value: newValue)
                        }
                    }

                    public enum __Attribute_AppSettings_setting: __AttributeNonOptional {
                        public typealias Container = AppSettings
                        public typealias Value = Bool
                        public static let name = "setting"
                        public static let defaultValue: Bool = true
                        public static let defaultRegistrar = __DefaultRegistrar()
                    }

                    public var $setting: __AttributeProxy<__Attribute_AppSettings_setting> {
                        return __AttributeProxy(attributeType: __Attribute_AppSettings_setting.self)
                    }

                    private static var state: __Settings_Container_Config {
                        __Settings_Container_Config(prefix: "")
                    }

                    public static var store: any UserDefaultsStore {
                        get {
                            state.store
                        }
                        set {
                            state.store = newValue
                        }
                    }

                    public static var prefix: String {
                        get {
                            state.prefix
                        }
                        set {
                            state.prefix = newValue
                        }
                    }
                }

                extension AppSettings: __Settings_Container {
                }
                """

            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testBool10() throws {
        #if canImport(SettingsMacros)
            let input = """
                @Settings(prefix: "app_") struct AppSettings {
                    @Setting var setting: Bool = true
                }
                """

            let expected = """
                struct AppSettings {
                    var setting: Bool {
                        get {
                            return __Attribute_AppSettings_setting.read()
                        }
                        set {
                            __Attribute_AppSettings_setting.write(value: newValue)
                        }
                    }

                    public enum __Attribute_AppSettings_setting: __AttributeNonOptional {
                        public typealias Container = AppSettings
                        public typealias Value = Bool
                        public static let name = "setting"
                        public static let defaultValue: Bool = true
                        public static let defaultRegistrar = __DefaultRegistrar()
                    }

                    public var $setting: __AttributeProxy<__Attribute_AppSettings_setting> {
                        return __AttributeProxy(attributeType: __Attribute_AppSettings_setting.self)
                    }

                    private static var state: __Settings_Container_Config {
                        __Settings_Container_Config(prefix: "app_")
                    }

                    public static var store: any UserDefaultsStore {
                        get {
                            state.store
                        }
                        set {
                            state.store = newValue
                        }
                    }

                    public static var prefix: String {
                        get {
                            state.prefix
                        }
                        set {
                            state.prefix = newValue
                        }
                    }
                }

                extension AppSettings: __Settings_Container {
                }
                """

            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testBool01() throws {
        #if canImport(SettingsMacros)
            let input = """
                @Settings struct AppSettings {}

                extension AppSettings {
                    @Setting var setting: Bool = true
                }
                """

            let expected = """
                struct AppSettings {

                    private static var state: __Settings_Container_Config {
                        __Settings_Container_Config(prefix: "")
                    }

                    public static var store: any UserDefaultsStore {
                        get {
                            state.store
                        }
                        set {
                            state.store = newValue
                        }
                    }

                    public static var prefix: String {
                        get {
                            state.prefix
                        }
                        set {
                            state.prefix = newValue
                        }
                    }
                }

                extension AppSettings {
                    var setting: Bool {
                        get {
                            return __Attribute_AppSettings_setting.read()
                        }
                        set {
                            __Attribute_AppSettings_setting.write(value: newValue)
                        }
                    }

                    public enum __Attribute_AppSettings_setting: __AttributeNonOptional {
                        public typealias Container = AppSettings
                        public typealias Value = Bool
                        public static let name = "setting"
                        public static let defaultValue: Bool = true
                        public static let defaultRegistrar = __DefaultRegistrar()
                    }

                    public var $setting: __AttributeProxy<__Attribute_AppSettings_setting> {
                        return __AttributeProxy(attributeType: __Attribute_AppSettings_setting.self)
                    }
                }

                extension AppSettings: __Settings_Container {
                }
                """

            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testBool11() throws {
        #if canImport(SettingsMacros)
            let input = """
                @Settings(prefix: "app_") struct AppSettings {}

                extension AppSettings {
                    @Setting var setting: Bool = true
                }
                """

            let expected = """
                struct AppSettings {

                    private static var state: __Settings_Container_Config {
                        __Settings_Container_Config(prefix: "app_")
                    }

                    public static var store: any UserDefaultsStore {
                        get {
                            state.store
                        }
                        set {
                            state.store = newValue
                        }
                    }

                    public static var prefix: String {
                        get {
                            state.prefix
                        }
                        set {
                            state.prefix = newValue
                        }
                    }
                }

                extension AppSettings {
                    var setting: Bool {
                        get {
                            return __Attribute_AppSettings_setting.read()
                        }
                        set {
                            __Attribute_AppSettings_setting.write(value: newValue)
                        }
                    }

                    public enum __Attribute_AppSettings_setting: __AttributeNonOptional {
                        public typealias Container = AppSettings
                        public typealias Value = Bool
                        public static let name = "setting"
                        public static let defaultValue: Bool = true
                        public static let defaultRegistrar = __DefaultRegistrar()
                    }

                    public var $setting: __AttributeProxy<__Attribute_AppSettings_setting> {
                        return __AttributeProxy(attributeType: __Attribute_AppSettings_setting.self)
                    }
                }

                extension AppSettings: __Settings_Container {
                }
                """

            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testNestedBool00() throws {
        #if canImport(SettingsMacros)
            let input = """
                @Settings struct AppSettings {}

                extension AppSettings { enum Profile {} }

                extension AppSettings.Profile {
                    @Setting var setting: Bool = true
                }
                """

            let expected = """
                struct AppSettings {

                    private static var state: __Settings_Container_Config {
                        __Settings_Container_Config(prefix: "")
                    }

                    public static var store: any UserDefaultsStore {
                        get {
                            state.store
                        }
                        set {
                            state.store = newValue
                        }
                    }

                    public static var prefix: String {
                        get {
                            state.prefix
                        }
                        set {
                            state.prefix = newValue
                        }
                    }
                }

                extension AppSettings { enum Profile {} 
                }

                extension AppSettings.Profile {
                    var setting: Bool {
                        get {
                            return __Attribute_AppSettings_Profile_setting.read()
                        }
                        set {
                            __Attribute_AppSettings_Profile_setting.write(value: newValue)
                        }
                    }

                    public enum __Attribute_AppSettings_Profile_setting: __AttributeNonOptional {
                        public typealias Container = AppSettings
                        public typealias Value = Bool
                        public static let name = "Profile::setting"
                        public static let defaultValue: Bool = true
                        public static let defaultRegistrar = __DefaultRegistrar()
                    }

                    public var $setting: __AttributeProxy<__Attribute_AppSettings_Profile_setting> {
                        return __AttributeProxy(attributeType: __Attribute_AppSettings_Profile_setting.self)
                    }
                }

                extension AppSettings: __Settings_Container {
                }
                """

            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testNestedBool10() throws {
        #if canImport(SettingsMacros)
            let input = """
                @Settings(prefix: "app_") struct AppSettings {}

                extension AppSettings { enum Profile {} }

                extension AppSettings.Profile {
                    @Setting var setting: Bool = true
                }
                """

            let expected = """
                struct AppSettings {

                    private static var state: __Settings_Container_Config {
                        __Settings_Container_Config(prefix: "app_")
                    }

                    public static var store: any UserDefaultsStore {
                        get {
                            state.store
                        }
                        set {
                            state.store = newValue
                        }
                    }

                    public static var prefix: String {
                        get {
                            state.prefix
                        }
                        set {
                            state.prefix = newValue
                        }
                    }
                }

                extension AppSettings { enum Profile {} 
                }

                extension AppSettings.Profile {
                    var setting: Bool {
                        get {
                            return __Attribute_AppSettings_Profile_setting.read()
                        }
                        set {
                            __Attribute_AppSettings_Profile_setting.write(value: newValue)
                        }
                    }

                    public enum __Attribute_AppSettings_Profile_setting: __AttributeNonOptional {
                        public typealias Container = AppSettings
                        public typealias Value = Bool
                        public static let name = "Profile::setting"
                        public static let defaultValue: Bool = true
                        public static let defaultRegistrar = __DefaultRegistrar()
                    }

                    public var $setting: __AttributeProxy<__Attribute_AppSettings_Profile_setting> {
                        return __AttributeProxy(attributeType: __Attribute_AppSettings_Profile_setting.self)
                    }
                }

                extension AppSettings: __Settings_Container {
                }
                """

            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testNestedBool01() throws {
        #if canImport(SettingsMacros)
            let input = """
                @Settings struct AppSettings { enum Profile {} }

                extension AppSettings.Profile {
                    @Setting var setting: Bool = true
                }
                """

            let expected = """
                struct AppSettings { enum Profile {} 

                    private static var state: __Settings_Container_Config {
                        __Settings_Container_Config(prefix: "")
                    }

                    public static var store: any UserDefaultsStore {
                        get {
                            state.store
                        }
                        set {
                            state.store = newValue
                        }
                    }

                    public static var prefix: String {
                        get {
                            state.prefix
                        }
                        set {
                            state.prefix = newValue
                        }
                    }
                }

                extension AppSettings.Profile {
                    var setting: Bool {
                        get {
                            return __Attribute_AppSettings_Profile_setting.read()
                        }
                        set {
                            __Attribute_AppSettings_Profile_setting.write(value: newValue)
                        }
                    }

                    public enum __Attribute_AppSettings_Profile_setting: __AttributeNonOptional {
                        public typealias Container = AppSettings
                        public typealias Value = Bool
                        public static let name = "Profile::setting"
                        public static let defaultValue: Bool = true
                        public static let defaultRegistrar = __DefaultRegistrar()
                    }

                    public var $setting: __AttributeProxy<__Attribute_AppSettings_Profile_setting> {
                        return __AttributeProxy(attributeType: __Attribute_AppSettings_Profile_setting.self)
                    }
                }

                extension AppSettings: __Settings_Container {
                }
                """

            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testNestedBool11() throws {
        #if canImport(SettingsMacros)
            let input = """
                @Settings(prefix: "app_") struct AppSettings { enum Profile {} }

                extension AppSettings.Profile {
                    @Setting var setting: Bool = true
                }
                """

            let expected = """
                struct AppSettings { enum Profile {} 

                    private static var state: __Settings_Container_Config {
                        __Settings_Container_Config(prefix: "app_")
                    }

                    public static var store: any UserDefaultsStore {
                        get {
                            state.store
                        }
                        set {
                            state.store = newValue
                        }
                    }

                    public static var prefix: String {
                        get {
                            state.prefix
                        }
                        set {
                            state.prefix = newValue
                        }
                    }
                }

                extension AppSettings.Profile {
                    var setting: Bool {
                        get {
                            return __Attribute_AppSettings_Profile_setting.read()
                        }
                        set {
                            __Attribute_AppSettings_Profile_setting.write(value: newValue)
                        }
                    }

                    public enum __Attribute_AppSettings_Profile_setting: __AttributeNonOptional {
                        public typealias Container = AppSettings
                        public typealias Value = Bool
                        public static let name = "Profile::setting"
                        public static let defaultValue: Bool = true
                        public static let defaultRegistrar = __DefaultRegistrar()
                    }

                    public var $setting: __AttributeProxy<__Attribute_AppSettings_Profile_setting> {
                        return __AttributeProxy(attributeType: __Attribute_AppSettings_Profile_setting.self)
                    }
                }

                extension AppSettings: __Settings_Container {
                }
                """

            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testNestedBool02() throws {
        #if canImport(SettingsMacros)
            let input = """
                @Settings struct AppSettings {}

                extension AppSettings { enum Profile {
                    @Setting var setting: Bool = true
                } }
                """

            let expected = """
                struct AppSettings {

                    private static var state: __Settings_Container_Config {
                        __Settings_Container_Config(prefix: "")
                    }

                    public static var store: any UserDefaultsStore {
                        get {
                            state.store
                        }
                        set {
                            state.store = newValue
                        }
                    }

                    public static var prefix: String {
                        get {
                            state.prefix
                        }
                        set {
                            state.prefix = newValue
                        }
                    }
                }

                extension AppSettings { enum Profile {
                    var setting: Bool {
                        get {
                            return __Attribute_AppSettings_Profile_setting.read()
                        }
                        set {
                            __Attribute_AppSettings_Profile_setting.write(value: newValue)
                        }
                    }

                    public enum __Attribute_AppSettings_Profile_setting: __AttributeNonOptional {
                        public typealias Container = AppSettings
                        public typealias Value = Bool
                        public static let name = "Profile::setting"
                        public static let defaultValue: Bool = true
                        public static let defaultRegistrar = __DefaultRegistrar()
                    }

                    public var $setting: __AttributeProxy<__Attribute_AppSettings_Profile_setting> {
                        return __AttributeProxy(attributeType: __Attribute_AppSettings_Profile_setting.self)
                    }
                } 
                }

                extension AppSettings: __Settings_Container {
                }
                """

            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testNestedBool12() throws {
        #if canImport(SettingsMacros)
            let input = """
                @Settings(prefix: "app_") struct AppSettings {}

                extension AppSettings { enum Profile {
                    @Setting var setting: Bool = true
                } }
                """

            let expected = """
                struct AppSettings {

                    private static var state: __Settings_Container_Config {
                        __Settings_Container_Config(prefix: "app_")
                    }

                    public static var store: any UserDefaultsStore {
                        get {
                            state.store
                        }
                        set {
                            state.store = newValue
                        }
                    }

                    public static var prefix: String {
                        get {
                            state.prefix
                        }
                        set {
                            state.prefix = newValue
                        }
                    }
                }

                extension AppSettings { enum Profile {
                    var setting: Bool {
                        get {
                            return __Attribute_AppSettings_Profile_setting.read()
                        }
                        set {
                            __Attribute_AppSettings_Profile_setting.write(value: newValue)
                        }
                    }

                    public enum __Attribute_AppSettings_Profile_setting: __AttributeNonOptional {
                        public typealias Container = AppSettings
                        public typealias Value = Bool
                        public static let name = "Profile::setting"
                        public static let defaultValue: Bool = true
                        public static let defaultRegistrar = __DefaultRegistrar()
                    }

                    public var $setting: __AttributeProxy<__Attribute_AppSettings_Profile_setting> {
                        return __AttributeProxy(attributeType: __Attribute_AppSettings_Profile_setting.self)
                    }
                } 
                }

                extension AppSettings: __Settings_Container {
                }
                """

            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }
    
    func testAllPropertyListTypes() throws {
        #if canImport(SettingsMacros)
            let allCases: [Case] = [
                // Non-optional PropertyList types
                Case(type: "Bool", initializer: "true", description: "Bool"),
                Case(type: "Int", initializer: "42", description: "Int"),
                Case(
                    type: "Double",
                    initializer: "3.14",
                    description: "Double"
                ),
                Case(type: "Float", initializer: "2.71", description: "Float"),
                Case(
                    type: "String",
                    initializer: "\"default\"",
                    description: "String"
                ),
                Case(type: "Date", initializer: "Date()", description: "Date"),
                Case(type: "Data", initializer: "Data()", description: "Data"),
                Case(
                    type: "Array<Any>",
                    initializer: "[]",
                    description: "Array of Any"
                ),
                Case(
                    type: "Dictionary<String, Any>",
                    initializer: "[:]",
                    description: "Dictionary of Any"
                ),

                // Optional PropertyList types
                Case(optionalType: "Bool", description: "Optional Bool"),
                Case(optionalType: "Int", description: "Optional Int"),
                Case(optionalType: "Double", description: "Optional Double"),
                Case(optionalType: "Float", description: "Optional Float"),
                Case(optionalType: "String", description: "Optional String"),
                Case(optionalType: "Date", description: "Optional Date"),
                Case(optionalType: "Data", description: "Optional Data"),
                Case(
                    optionalType: "Array<Any>",
                    description: "Optional Array of Any"
                ),
                Case(
                    optionalType: "Dictionary<String, Any>",
                    description: "Optional Dictionary of Any"
                ),

                // Collections
                Case(
                    type: "[String]",
                    initializer: "[]",
                    description: "[String]"
                ),
                Case(
                    type: "Array<Int>",
                    initializer: "[]",
                    description: "Array<Int>"
                ),
                Case(
                    type: "[String: Int]",
                    initializer: "[:]",
                    description: "[String: Int]"
                ),
            ]

            for value in allCases {
                let testCase = TestCase(
                    description: value.description,
                    containerQualifiedName: "AppSettings",
                    valueType: value.type,
                    initialValue: value.initialValue
                )
                let input = makeSource(for: testCase)
                let expected = makeExpectedExpandedSource(for: testCase)
                assertMacroExpansion(
                    input,
                    expandedSource: expected,
                    macros: testMacros
                )
            }
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testNestedContainer() throws {
        #if canImport(SettingsMacros)
            let testCase = TestCase(
                description: "nested property",
                containerQualifiedName: "AppSettings.UserSettings",
                valueType: "String",
                initialValue: "\"default\""
            )

            let input = makeSource(for: testCase)
            let expected = makeExpectedExpandedSource(for: testCase)
            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testNestedContainer0() throws {
        #if canImport(SettingsMacros)

            let input = """
                @Settings struct AppSettings {}
                extension AppSettings { enum UserSettings {} }

                extension AppSettings.UserSettings {
                    @Setting var setting: String = "default"
                }
                """

            let expected = """
                struct AppSettings {

                    private static var state: __Settings_Container_Config {
                        __Settings_Container_Config(prefix: "")
                    }

                    public static var store: any UserDefaultsStore {
                        get {
                            state.store
                        }
                        set {
                            state.store = newValue
                        }
                    }

                    public static var prefix: String {
                        get {
                            state.prefix
                        }
                        set {
                            state.prefix = newValue
                        }
                    }
                }
                extension AppSettings { enum UserSettings {} 
                }

                extension AppSettings.UserSettings {
                    var setting: String {
                        get {
                            return __Attribute_AppSettings_UserSettings_setting.read()
                        }
                        set {
                            __Attribute_AppSettings_UserSettings_setting.write(value: newValue)
                        }
                    }

                    public enum __Attribute_AppSettings_UserSettings_setting: __AttributeNonOptional {
                        public typealias Container = AppSettings
                        public typealias Value = String
                        public static let name = "UserSettings::setting"
                        public static let defaultValue: String = "default"
                        public static let defaultRegistrar = __DefaultRegistrar()
                    }

                    public var $setting: __AttributeProxy<__Attribute_AppSettings_UserSettings_setting> {
                        return __AttributeProxy(attributeType: __Attribute_AppSettings_UserSettings_setting.self)
                    }
                }

                extension AppSettings: __Settings_Container {
                }
                """

            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testNestedContainer2() throws {
        #if canImport(SettingsMacros)
            let input = """
                @Settings struct AppSettings {}
                extension AppSettings { enum UserSettings {
                    @Setting var setting: String = "default"
                } }
                """

            let expected = """
                struct AppSettings {

                    private static var state: __Settings_Container_Config {
                        __Settings_Container_Config(prefix: "")
                    }

                    public static var store: any UserDefaultsStore {
                        get {
                            state.store
                        }
                        set {
                            state.store = newValue
                        }
                    }

                    public static var prefix: String {
                        get {
                            state.prefix
                        }
                        set {
                            state.prefix = newValue
                        }
                    }
                }
                extension AppSettings { enum UserSettings {
                    var setting: String {
                        get {
                            return __Attribute_AppSettings_UserSettings_setting.read()
                        }
                        set {
                            __Attribute_AppSettings_UserSettings_setting.write(value: newValue)
                        }
                    }

                    public enum __Attribute_AppSettings_UserSettings_setting: __AttributeNonOptional {
                        public typealias Container = AppSettings
                        public typealias Value = String
                        public static let name = "UserSettings::setting"
                        public static let defaultValue: String = "default"
                        public static let defaultRegistrar = __DefaultRegistrar()
                    }

                    public var $setting: __AttributeProxy<__Attribute_AppSettings_UserSettings_setting> {
                        return __AttributeProxy(attributeType: __Attribute_AppSettings_UserSettings_setting.self)
                    }
                } 
                }

                extension AppSettings: __Settings_Container {
                }
                """

            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testStaticProperty() throws {
        #if canImport(SettingsMacros)
            let testCase = TestCase(
                description: "static property",
                containerQualifiedName: "AppSettings",
                valueType: "String",
                initialValue: "\"default\"",
                isStatic: true
            )

            let input = makeSource(for: testCase)
            let expected = makeExpectedExpandedSource(for: testCase)
            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

    func testCodableWithEncodingStrategy() throws {
        #if canImport(SettingsMacros)
            let testCase = TestCase(
                description: "Codable with encoding",
                containerQualifiedName: "AppSettingsd",
                valueType: "CustomValue",
                initialValue: ".init()"
            )

            let input = makeSource(for: testCase)
            let expected = makeExpectedExpandedSource(for: testCase)
            assertMacroExpansion(
                input,
                expandedSource: expected,
                macros: testMacros
            )
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }
}

extension SettingsSettingMacroExpansionTests {

    private struct TestCase {
        let description: String
        var containerQualifiedName: String
        let valueType: String
        var initialValue: String = ""
        var macroAttributes: String = ""
        var isStatic: Bool = false

        var isOptional: Bool {
            valueType.hasSuffix("?")
        }

        var protocolName: String {
            isOptional ? "__AttributeOptional" : "__AttributeNonOptional"
        }

        var wrappedDecl: String {
            guard isOptional else {
                return ""
            }
            // Extract unwrapped type from Optional
            let unwrappedType = String(valueType.dropLast())
            return "public typealias Wrapped = \(unwrappedType)"
        }
    }

    private func makeSource(
        for testCase: TestCase,
    ) -> String {
        let initializer =
            testCase.initialValue.isEmpty ? "" : " = \(testCase.initialValue)"
        let staticModifier = testCase.isStatic ? "static " : ""

        let (nestedContainerDecl, containerBaseName) = makeNestedContainerDecl(
            from: testCase
        )

        let template: String =
            """
            @Settings struct \(containerBaseName)\(testCase.macroAttributes) {}\
            \(nestedContainerDecl, indentation: 0)
            extension \(testCase.containerQualifiedName) {
                @Setting\(testCase.macroAttributes) \(staticModifier)var setting: \(testCase.valueType)\(initializer)
            }
            """
        return template
    }

    private func attributeTypeName(
        containerQualifiedName: String,
        property: String
    ) -> String {
        let sanitizedContainer = containerQualifiedName.replacingOccurrences(
            of: ".",
            with: "_"
        )
        return "__Attribute_\(sanitizedContainer)_\(property)"
    }

    private func makeNestedContainerDecl(
        from testCase: TestCase,
        forSource: Bool = true
    ) -> (decl: String, container: String) {
        // Make nested container declaration:
        var nestedContainerDecl: String = ""
        let components = testCase.containerQualifiedName.split(separator: ".")
            .map(String.init)
        assert(components.count > 0)
        assert(components.count <= 2)
        let containerBaseName = components.first!
        if components.count > 1 {
            // define intermediate nested container(s)
            // only one level is needed for current tests, so just the first level
            let root = components[0]
            let nested = components[1]
            if forSource {
                nestedContainerDecl = "extension \(root) { enum \(nested) {} }"
            } else {
                nestedContainerDecl =
                    "extension \(root) { enum \(nested) {} \n}\n"  // Note: the swift syntax will add a new line character after the enum decl.
            }
        }
        return (nestedContainerDecl, containerBaseName)
    }

    private func makeExpectedExpandedSource(
        for testCase: TestCase,
        attributeArguments: String? = nil,
        nameOverride: String? = nil
    ) -> String {
        let initializer =
            testCase.initialValue.isEmpty ? "" : " = \(testCase.initialValue)"
        let staticModifier = testCase.isStatic ? "static " : ""

        let (nestedContainerDecl, containerBaseName) = makeNestedContainerDecl(
            from: testCase,
            forSource: false
        )

        // make name decl
        let nestedNameComponents =
            testCase.containerQualifiedName.split(separator: ".").dropFirst(1)
            .map(String.init) + ["setting"]
        let name = nameOverride ?? nestedNameComponents.joined(separator: "::")

        // default decls (only for non-optional)
        let defaultValueDecl =
            initializer.isEmpty
            ? ""
            : "public static let defaultValue: \(testCase.valueType)\(initializer)"
        let defaultRegistrarDecl =
            initializer.isEmpty
            ? "" : "public static let defaultRegistrar = __DefaultRegistrar()"

        // make enum name:
        let enumName =
            "__Attribute_\(testCase.containerQualifiedName.split(separator: ".").joined(separator: "_"))_setting"

        let encodingBlock: String
        if let attrArgs = attributeArguments,
            attrArgs.contains("(encoding: .json)")
        {
            encodingBlock =
                """
                public static var encoder: some AttributeEncoding {
                    return JSONEncoder()
                }
                public static var decoder: some AttributeDecoding {
                    return JSONDecoder()
                }
                """
        } else {
            encodingBlock = ""
        }

        let proxyAccessor = """

                public \(staticModifier)var $setting: __AttributeProxy<\(enumName)> {
                    return __AttributeProxy(attributeType: \(enumName).self)
                }
            """

        // Extract prefix from test case macro attributes
        let prefixValue: String
        if testCase.macroAttributes.contains("prefix:") {
            // Extract the prefix value from macro attributes
            if let match = testCase.macroAttributes.range(
                of: #"prefix: "([^"]*)"#,
                options: .regularExpression
            ) {
                let prefixMatch = testCase.macroAttributes[match]
                if let valueStart = prefixMatch.range(of: "\"") {
                    let afterQuote = prefixMatch[valueStart.upperBound...]
                    if let endQuote = afterQuote.firstIndex(of: "\"") {
                        prefixValue = String(afterQuote[..<endQuote])
                    } else {
                        prefixValue = ""
                    }
                } else {
                    prefixValue = ""
                }
            } else {
                prefixValue = ""
            }
        } else {
            prefixValue = ""
        }

        // Config infrastructure - always add to the base container (AppSettings)
        // The @Settings macro is on the base container, so Config goes there
        let configInfrastructure: String
        configInfrastructure = """


                private static var state: __Settings_Container_Config {
                    __Settings_Container_Config(prefix: "\(prefixValue)")
                }

                public static var store: any UserDefaultsStore {
                    get {
                        state.store
                    }
                    set {
                        state.store = newValue
                    }
                }

                public static var prefix: String {
                    get {
                        state.prefix
                    }
                    set {
                        state.prefix = newValue
                    }
                }
            """

        let template = """
            struct \(containerBaseName) {\(configInfrastructure)
            }
            \(nestedContainerDecl, indentation: 0, prependNewLine: false)\
            extension \(testCase.containerQualifiedName) {
                \(staticModifier)var setting: \(testCase.valueType) {
                    get {
                        return \(enumName).read()
                    }
                    set {
                        \(enumName).write(value: newValue)
                    }
                }

                public enum \(enumName): \(testCase.protocolName) {
                    public typealias Container = \(containerBaseName)
                    public typealias Value = \(testCase.valueType)\
            \(testCase.wrappedDecl, indentation: 8)
                    public static let name = "\(name)"\
            \(defaultValueDecl, indentation: 8)\
            \(defaultRegistrarDecl, indentation: 8)\
            \(encodingBlock, indentation: 8)
                }
            \(proxyAccessor, indentation: 0, prependNewLine: false)
            }

            extension \(containerBaseName): __Settings_Container {
            }
            """
        return template
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(
        _ value: String,
        indentation: Int,
        prependNewLine: Bool = true
    ) {
        guard !value.isEmpty else {
            return
        }
        let spaces = String(repeating: " ", count: indentation)
        if prependNewLine {
            appendLiteral("\n")
        }
        appendLiteral(spaces)
        let string = value.split(
            separator: "\n",
            omittingEmptySubsequences: false
        ).joined(separator: "\n" + spaces)
        appendLiteral(string)
    }
}
