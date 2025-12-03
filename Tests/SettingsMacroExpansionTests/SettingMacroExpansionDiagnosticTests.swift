import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import Foundation

@testable import SettingsMacros

final class SettingMacroExpansionDiagnosticTests: XCTestCase {
    private let testMacros: [String: Macro.Type] = [
        "Setting": SettingMacro.self,
        "Settings": SettingsMacro.self,
    ]

    func testEncodingStrategyRejectedForScalarPropertyListTypes() throws {
        let tests: [EncodingDiagnosticCase] = [
            .init(description: "Bool", type: "Bool", initialValue: "true"),
            .init(description: "Int", type: "Int", initialValue: "1"),
            .init(description: "Double", type: "Double", initialValue: "2.5"),
            .init(description: "Float", type: "Float", initialValue: "1.5"),
            .init(description: "String", type: "String", initialValue: "\"hello\""),
            .init(description: "Date", type: "Date", initialValue: "Date(timeIntervalSince1970: 0)"),
            .init(description: "Data", type: "Data", initialValue: "Data()"),
            .init(description: "URL", type: "URL", initialValue: "URL(string: \"https://example.com/resource\")!"),
            .init(description: "Any", type: "Any", initialValue: "\"value\" as Any"),
        ]
        let cases = tests.map { test in
            var test = test
            test.parameterList = "(encoding: .json)"
            test.fixedParameterList = ""
            test.fixIts = [EncodingDiagnosticCase.encodingArgumentFixItMessage]
            return test
        }
        try assertEncodingRejected(for: cases)
    }

    func testEncoderDecoderStrategyRejectedForScalarPropertyListTypes1() throws {
        let tests: [EncodingDiagnosticCase] = [
            .init(description: "Bool", type: "Bool", initialValue: "true"),
            .init(description: "Int", type: "Int", initialValue: "1"),
            .init(description: "Double", type: "Double", initialValue: "2.5"),
            .init(description: "Float", type: "Float", initialValue: "1.5"),
            .init(description: "String", type: "String", initialValue: "\"hello\""),
            .init(description: "Date", type: "Date", initialValue: "Date(timeIntervalSince1970: 0)"),
            .init(description: "Data", type: "Data", initialValue: "Data()"),
            .init(description: "URL", type: "URL", initialValue: "URL(string: \"https://example.com/resource\")!"),
            .init(description: "Any", type: "Any", initialValue: "\"value\" as Any")
        ]
        let cases = tests.map { test in
            var test = test
            test.parameterList = "(encoder: JSONEncoder(), decoder: JSONDecoder())"
            test.fixedParameterList = ""
            test.fixIts = [EncodingDiagnosticCase.encoderDecoderFixItMessage]
            return test
        }
        try assertEncodingRejected(for: cases)
    }

    func testEncoderDecoderStrategyRejectedForScalarPropertyListTypes2() throws {
        let tests: [EncodingDiagnosticCase] = [
            .init(description: "Bool", type: "Bool", initialValue: "true"),
            .init(description: "Int", type: "Int", initialValue: "1"),
            .init(description: "Double", type: "Double", initialValue: "2.5"),
            .init(description: "Float", type: "Float", initialValue: "1.5"),
            .init(description: "String", type: "String", initialValue: "\"hello\""),
            .init(description: "Date", type: "Date", initialValue: "Date(timeIntervalSince1970: 0)"),
            .init(description: "Data", type: "Data", initialValue: "Data()"),
            .init(description: "URL", type: "URL", initialValue: "URL(string: \"https://example.com/resource\")!"),
            .init(description: "Any", type: "Any", initialValue: "\"value\" as Any")
        ]
        let cases = tests.map { test in
            var test = test
            test.parameterList = "(name: \"value\", encoder: JSONEncoder(), decoder: JSONDecoder())"
            test.fixedParameterList = "(name: \"value\")"
            test.fixIts = [EncodingDiagnosticCase.encoderDecoderFixItMessage]
            return test
        }
        try assertEncodingRejected(for: cases)
    }

    // TODO: enable again
    // func testMissingEncoderRejectedForScalarPropertyListTypes() throws {
    //     let tests: [EncodingDiagnosticCase] = [
    //         .init(description: "Bool", type: "Bool", initialValue: "true"),
    //         .init(description: "Int", type: "Int", initialValue: "1"),
    //         .init(description: "Double", type: "Double", initialValue: "2.5"),
    //         .init(description: "Float", type: "Float", initialValue: "1.5"),
    //         .init(description: "String", type: "String", initialValue: "\"hello\""),
    //         .init(description: "Date", type: "Date", initialValue: "Date(timeIntervalSince1970: 0)"),
    //         .init(description: "Data", type: "Data", initialValue: "Data()"),
    //         .init(description: "URL", type: "URL", initialValue: "URL(string: \"https://example.com/resource\")!"),
    //         .init(description: "Any", type: "Any", initialValue: "\"value\" as Any")
    //     ]
    //     let cases = tests.map { test in
    //         var test = test
    //         test.parameterList = "(decoder: JSONDecoder())"
    //         test.fixedParameterList = "(decoder: JSONDecoder())"
    //         test.fixIts = [EncodingDiagnosticCase.encoderDecoderFixItMessage]
    //         return test
    //     }
    //     try assertEncodingRejected(for: cases)
    // }

    func testEncodingStrategyRejectedForCollectionPropertyListTypes() throws {
        let cases: [EncodingDiagnosticCase] = [
            .init(description: "String Array", type: "[String]", initialValue: "[\"alpha\", \"beta\"]"),
            .init(description: "Integer Array", type: "Array<Int>", initialValue: "[1, 2, 3]"),
            .init(description: "Dictionary String Int", type: "[String: Int]", initialValue: "[\"count\": 1]"),
            .init(description: "Dictionary With Arrays", type: "Dictionary<String, [Int]>", initialValue: "[\"numbers\": [1, 2, 3]]"),
            .init(description: "Array Of Dictionaries", type: "Array<Dictionary<String, Int>>", initialValue: "[[\"score\": 42]]"),
            .init(description: "Dictionary With Any Values", type: "[String: Any]", initialValue: "[\"flag\": true] as [String: Any]"),
        ]
        try assertEncodingRejected(for: cases)
    }
    
    func testEncodingStrategyRejectedForPathologicalPropertyListTypes() throws {
        let cases: [EncodingDiagnosticCase] = [
            .init(
                description: "Foundation Qualified URL",
                type: "Foundation.URL",
                initialValue: "URL(string: \"https://example.com/qualified\")!"
            ),
            .init(
                description: "Swift Namespace Array Dictionary",
                type: "Swift.Array<Swift.Dictionary<String, Swift.Int>>",
                initialValue: "[[\"count\": 1]]"
            ),
            .init(
                description: "Whitespace Heavy Dictionary",
                type: "Dictionary < String , Dictionary < String , Int > >",
                initialValue: "[\"stats\": [\"wins\": 3]]"
            ),
            .init(
                description: "Dictionary With Optional Arrays",
                type: "[String: Optional<[Int]>]",
                initialValue: "[\"numbers\": [1, 2, 3]]"
            ),
            .init(
                description: "Nested Collections",
                type: "Dictionary<String, Dictionary<String, [Int]>>",
                initialValue: "[\"metrics\": [\"scores\": [1, 2]]]"
            )
        ]
        try assertEncodingRejected(for: cases)
    }
    
    func testExplicitCoderProvidersRejectedForPropertyListTypes() throws {
#if canImport(SettingsMacros)
        assertMacroExpansion(
                """
                extension UserDefaultsStandard {
                    @Setting(
                        encoder: JSONEncoder(),
                        decoder: JSONDecoder()
                    ) var value: String = "hello"
                }
                """,
                expandedSource: """
                    extension UserDefaultsStandard {
                        var value: String = "hello"
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message:
                            "`encoding`/`encoder` arguments are only supported for Codable types. `String` already stores natively in UserDefaults.",
                        line: 2,
                        column: 5,
                        fixIts: [FixItSpec(message: EncodingDiagnosticCase.encoderDecoderFixItMessage)]
                    )
                ],
                macros: testMacros,
                applyFixIts: [EncodingDiagnosticCase.encoderDecoderFixItMessage],
                fixedSource: """
                    extension UserDefaultsStandard {
                        @Setting var value: String = "hello"
                    }
                    """
        )
#else
        throw XCTSkip(
            "macros are only supported when running tests for the host platform"
        )
#endif
    }
    
    func testFixItRemovesEncodingButKeepsName() throws {
    #if canImport(SettingsMacros)
        assertMacroExpansion(
            """
            extension UserDefaultsStandard {
                @Setting(name: "custom.key", encoding: .json) var value: String = "hello"
            }
            """,
            expandedSource: """
                extension UserDefaultsStandard {
                    var value: String = "hello"
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message:
                        "`encoding`/`encoder` arguments are only supported for Codable types. `String` already stores natively in UserDefaults.",
                    line: 2,
                    column: 5,
                    fixIts: [FixItSpec(message: EncodingDiagnosticCase.encodingArgumentFixItMessage)]
                )
            ],
            macros: testMacros,
            applyFixIts: [EncodingDiagnosticCase.encodingArgumentFixItMessage],
            fixedSource: """
                extension UserDefaultsStandard {
                    @Setting(name: "custom.key") var value: String = "hello"
                }
                """
        )
    #else
        throw XCTSkip(
            "macros are only supported when running tests for the host platform"
        )
    #endif
    }

    func testFixItRemovesEncodingAndParenthesesWhenAlone() throws {
    #if canImport(SettingsMacros)
        assertMacroExpansion(
            """
            extension UserDefaultsStandard {
                @Setting(encoding: .plist) var value: Int = 1
            }
            """,
            expandedSource: """
                extension UserDefaultsStandard {
                    var value: Int = 1
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message:
                        "`encoding`/`encoder` arguments are only supported for Codable types. `Int` already stores natively in UserDefaults.",
                    line: 2,
                    column: 5,
                    fixIts: [FixItSpec(message: EncodingDiagnosticCase.encodingArgumentFixItMessage)]
                )
            ],
            macros: testMacros,
            applyFixIts: [EncodingDiagnosticCase.encodingArgumentFixItMessage],
            fixedSource: """
                extension UserDefaultsStandard {
                    @Setting var value: Int = 1
                }
                """
        )
    #else
        throw XCTSkip(
            "macros are only supported when running tests for the host platform"
        )
    #endif
    }

    func testFixItRemovesEncoderDecoderButKeepsName() throws {
    #if canImport(SettingsMacros)
        assertMacroExpansion(
            """
            extension UserDefaultsStandard {
                @Setting(name: "another.key", encoder: JSONEncoder(), decoder: JSONDecoder()) var value: String = "world"
            }
            """,
            expandedSource: """
                extension UserDefaultsStandard {
                    var value: String = "world"
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message:
                        "`encoding`/`encoder` arguments are only supported for Codable types. `String` already stores natively in UserDefaults.",
                    line: 2,
                    column: 5,
                    fixIts: [FixItSpec(message: EncodingDiagnosticCase.encoderDecoderFixItMessage)]
                )
            ],
            macros: testMacros,
            applyFixIts: [EncodingDiagnosticCase.encoderDecoderFixItMessage],
            fixedSource: """
                extension UserDefaultsStandard {
                    @Setting(name: "another.key") var value: String = "world"
                }
                """
        )
    #else
        throw XCTSkip(
            "macros are only supported when running tests for the host platform"
        )
    #endif
    }
}

extension SettingMacroExpansionDiagnosticTests {
    
    struct EncodingDiagnosticCase {
        static let encodingArgumentFixItMessage = "Remove the `encoding` argument for property-list values."
        static let encoderDecoderFixItMessage = "Remove the `encoder` and `decoder` arguments for property-list values."
        
        init(
            description: String,
            type: String,
            initialValue: String,
        ) {
            self.description = description
            self.type = type
            self.initialValue = initialValue
        }
        
        var parameterList: String = "(encoding: .json)"
        var fixedParameterList: String = ""
        var description: String
        var type: String
        var initialValue: String
        var fixIts: [String] = [encodingArgumentFixItMessage]
    }

    private func assertEncodingRejected(for cases: [EncodingDiagnosticCase]) throws {
        #if canImport(SettingsMacros)
            for testCase in cases {
                let normalizedType = testCase.type.trimmingCharacters(in: .whitespacesAndNewlines)
                let initialiser = testCase.initialValue.isEmpty ? "" : " = \(testCase.initialValue)"
                assertMacroExpansion(
                    """
                    extension UserDefaultsStandard {
                        @Setting\(testCase.parameterList) var value: \(testCase.type) = \(testCase.initialValue)
                    }
                    """,
                    expandedSource: """
                        extension UserDefaultsStandard {
                            var value: \(testCase.type)\(initialiser)
                        }
                        """,
                    diagnostics: [
                        DiagnosticSpec(
                            message:
                                "`encoding`/`encoder` arguments are only supported for Codable types. `\(normalizedType)` already stores natively in UserDefaults.",
                            line: 2,
                            column: 5,
                            fixIts: testCase.fixIts.map { FixItSpec(message: $0) }
                        )
                    ],
                    macros: testMacros,
                    applyFixIts: testCase.fixIts,
                    fixedSource: """
                        extension UserDefaultsStandard {
                            @Setting\(testCase.fixedParameterList) var value: \(testCase.type)\(initialiser)
                        }
                        """
                )
            }
        #else
            throw XCTSkip(
                "macros are only supported when running tests for the host platform"
            )
        #endif
    }

}

