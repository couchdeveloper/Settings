import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
import SettingsMacros

@Suite("UserDefault Macro Error Tests")
struct SettingMacroErrorTests {

    // MARK: - Invalid Declaration Tests

    @Test("Error: Not applied to a variable")
    func testErrorNotAppliedToVariable() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                extension UserDefaultsStandard {
                    @Setting func invalidFunction() {}
                }
                """,
                expandedSource: """
                    extension UserDefaultsStandard {
                        @Setting func invalidFunction() {}
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message:
                            "@Setting can only be applied to variable declarations",
                        line: 2,
                        column: 5
                    )
                ],
                macros: ["Setting": SettingMacro.self]
            )
        #endif
    }

    @Test("Error: Not applied to a property in an extension")
    func testErrorNotInExtension() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                struct SomeStruct {
                    @Setting var invalidProperty: String = "default"
                }
                """,
                expandedSource: """
                    struct SomeStruct {
                        @Setting var invalidProperty: String = "default"
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "No valid UserDefaults container type found",
                        line: 2,
                        column: 5
                    )
                ],
                macros: ["Setting": SettingMacro.self]
            )
        #endif
    }

    @Test("Error: Cannot determine type")
    func testErrorCannotDetermineType() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                extension UserDefaultsStandard {
                    @Setting var invalidProperty = someFunction()
                }
                """,
                expandedSource: """
                    extension UserDefaultsStandard {
                        @Setting var invalidProperty = someFunction()
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Cannot determine property type",
                        line: 2,
                        column: 5
                    )
                ],
                macros: ["Setting": SettingMacro.self]
            )
        #endif
    }

    @Test("Error: Complex initial value")
    func testErrorComplexInitialValue() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                extension UserDefaultsStandard {
                    @Setting var invalidProperty: String = String("complex") + "value"
                }
                """,
                expandedSource: """
                    extension UserDefaultsStandard {
                        @Setting var invalidProperty: String = String("complex") + "value"
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Initial value must be a literal",
                        line: 2,
                        column: 5
                    )
                ],
                macros: ["Setting": SettingMacro.self]
            )
        #endif
    }

    // MARK: - Type Mismatch Tests

    @Test("Error: Type annotation doesn't match initial value")
    func testErrorTypeMismatch() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                extension UserDefaultsStandard {
                    @Setting var invalidProperty: String = 42
                }
                """,
                expandedSource: """
                    extension UserDefaultsStandard {
                        @Setting var invalidProperty: String = 42
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Initial value must be a literal",
                        line: 2,
                        column: 5
                    )
                ],
                macros: ["Setting": SettingMacro.self]
            )
        #endif
    }

    // MARK: - Complex Type Tests

    @Test("Array property with default value")
    func testArrayPropertyWithDefault() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                extension UserDefaultsStandard {
                    @Setting var tags: [String] = []
                }
                """,
                expandedSource: """
                    extension UserDefaultsStandard {
                        var tags: [String] {
                            get {
                                return self[__Attribute_UserDefaultsStandard_tags.self]
                            }
                            set {
                                self[__Attribute_UserDefaultsStandard_tags.self] = newValue
                            }
                        }
                    }

                    public enum __Attribute_UserDefaultsStandard_tags: __Attribute {
                        public typealias Container = UserDefaultsStandard
                        public typealias Value = [String]
                        public static let name = "tags"
                        public static let defaultValue: [String] = []
                    }
                    """,
                macros: ["Setting": SettingMacro.self]
            )
        #endif
    }

    @Test("Dictionary property with default value")
    func testDictionaryPropertyWithDefault() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                extension UserDefaultsStandard {
                    @Setting var settings: [String: Any] = [:]
                }
                """,
                expandedSource: """
                    extension UserDefaultsStandard {
                        var settings: [String: Any] {
                            get {
                                return self[__Attribute_UserDefaultsStandard_settings.self]
                            }
                            set {
                                self[__Attribute_UserDefaultsStandard_settings.self] = newValue
                            }
                        }
                    }

                    public enum __Attribute_UserDefaultsStandard_settings: __Attribute {
                        public typealias Container = UserDefaultsStandard
                        public typealias Value = [String: Any]
                        public static let name = "settings"
                        public static let defaultValue: [String: Any] = [:]
                    }
                    """,
                macros: ["Setting": SettingMacro.self]
            )
        #endif
    }

    // MARK: - Edge Case Tests

    @Test("Property with underscore prefix")
    func testUnderscorePrefix() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                extension UserDefaultsStandard {
                    @Setting var _privateProperty: String = "private"
                }
                """,
                expandedSource: """
                    extension UserDefaultsStandard {
                        var _privateProperty: String {
                            get {
                                return self[__Attribute_UserDefaultsStandard__privateProperty.self]
                            }
                            set {
                                self[__Attribute_UserDefaultsStandard__privateProperty.self] = newValue
                            }
                        }
                    }

                    public enum __Attribute_UserDefaultsStandard__privateProperty: __Attribute {
                        public typealias Container = UserDefaultsStandard
                        public typealias Value = String
                        public static let name = "_privateProperty"
                        public static let defaultValue: String = "private"
                    }
                    """,
                macros: ["Setting": SettingMacro.self]
            )
        #endif
    }

    @Test("Property with numbers in name")
    func testNumbersInName() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                extension UserDefaultsStandard {
                    @Setting var setting123: String = "test"
                }
                """,
                expandedSource: """
                    extension UserDefaultsStandard {
                        var setting123: String {
                            get {
                                return self[__Attribute_UserDefaultsStandard_setting123.self]
                            }
                            set {
                                self[__Attribute_UserDefaultsStandard_setting123.self] = newValue
                            }
                        }
                    }

                    public enum __Attribute_UserDefaultsStandard_setting123: __Attribute {
                        public typealias Container = UserDefaultsStandard
                        public typealias Value = String
                        public static let name = "setting123"
                        public static let defaultValue: String = "test"
                    }
                    """,
                macros: ["Setting": SettingMacro.self]
            )
        #endif
    }

    @Test("Property with special characters in custom name")
    func testSpecialCharactersInCustomKey() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                extension UserDefaultsStandard {
                    @Setting(name: "com.myapp.special-key_123") var specialKey: String = "value"
                }
                """,
                expandedSource: """
                    extension UserDefaultsStandard {
                        var specialKey: String {
                            get {
                                return self[__Attribute_UserDefaultsStandard_specialKey.self]
                            }
                            set {
                                self[__Attribute_UserDefaultsStandard_specialKey.self] = newValue
                            }
                        }
                    }

                    public enum __Attribute_UserDefaultsStandard_specialKey: __Attribute {
                        public typealias Container = UserDefaultsStandard
                        public typealias Value = String
                        public static let name = "com.myapp.special-key_123"
                        public static let defaultValue: String = "value"
                    }
                    """,
                macros: ["Setting": SettingMacro.self]
            )
        #endif
    }

    // MARK: - Nil Literal Tests

    @Test("Optional property with nil literal")
    func testOptionalWithNilLiteral() throws {
        #if canImport(SettingsMacros)
            assertMacroExpansion(
                """
                extension UserDefaultsStandard {
                    @Setting var optionalWithNil: String? = nil
                }
                """,
                expandedSource: """
                    extension UserDefaultsStandard {
                        @Setting var optionalWithNil: String? = nil
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message:
                            "Optional @Setting properties should not have an initial value",
                        line: 2,
                        column: 5
                    )
                ],
                macros: ["Setting": SettingMacro.self]
            )
        #endif
    }
}
