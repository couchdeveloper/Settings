import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct SettingsMacro {}

extension SettingsMacro: MemberMacro {

    // Implementation of the `@Settings` container macro
    //
    // This macro generates the configuration infrastructure for a container type.
    // The container must manually conform to `__Settings_Container`.
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf decl: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // Extract the prefix from the macro arguments
        let initialPrefix: String? = try extractPrefix(from: node)
        if let prefix = initialPrefix {
            try validatePrefix(prefix)
        }
        let literalPrefix = initialPrefix == nil ? "" : initialPrefix!

        let declSyntax = DeclSyntax(
            """
            struct Config {
                var store: any UserDefaultsStore = Foundation.UserDefaults.standard
                var prefix: String = "\(raw: literalPrefix)"
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
            """
        )
        return [declSyntax]
    }
}

extension SettingsMacro: ExtensionMacro {

    // MARK: Extension Macro Implementation

    struct Attributes {
        var prefix: String?
        var suiteName: String?
    }

    static func validatePrefix(_ prefix: String) throws {
        // The prefix string needs to be KVC compliant.
        guard !prefix.contains(".") else {
            throw MacroError.invalidPrefix(
                "Invalid prefix: \(prefix). The prefix is not KVC compliant. It must not contain dots (\".\")."
            )
        }
    }

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {

        // Generate an extension that adds conformance to __Settings_Container
        let extensionDecl = ExtensionDeclSyntax(
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax {
                InheritedTypeSyntax(
                    type: IdentifierTypeSyntax(
                        name: .identifier("__Settings_Container")
                    )
                )
            },
            memberBlock: MemberBlockSyntax(members: [])
        )

        return [extensionDecl]
    }
}

// MARK: - Helper Methods

extension SettingsMacro {

    static func extractAttributes(from node: AttributeSyntax) throws
        -> Attributes
    {
        Attributes(
            prefix: try extractPrefix(from: node),
            suiteName: try extractSuiteName(from: node)
        )
    }

    /// Extracts the prefix parameter from the macro arguments.
    /// Returns `nil` if no prefix is specified.
    private static func extractPrefix(from node: AttributeSyntax) throws
        -> String?
    {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self)
        else {
            return nil  // Default to nil if no arguments
        }

        for argument in arguments {
            if argument.label?.text == "prefix" {
                if let stringLiteral = argument.expression.as(
                    StringLiteralExprSyntax.self
                ) {
                    return stringLiteral.segments.first?.as(
                        StringSegmentSyntax.self
                    )?.content.text ?? ""
                }
            }
        }

        // If no prefix parameter is found, check for unlabeled first argument
        if let firstArgument = arguments.first,
            firstArgument.label == nil,
            let stringLiteral = firstArgument.expression.as(
                StringLiteralExprSyntax.self
            )
        {
            return stringLiteral.segments.first?.as(StringSegmentSyntax.self)?
                .content.text ?? ""
        }

        return nil  // Default to nil prefix
    }

    /// Extracts the suiteName parameter from the macro arguments
    private static func extractSuiteName(from node: AttributeSyntax) throws
        -> String?
    {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self)
        else {
            return nil  // Default to nil if no arguments
        }

        for argument in arguments {
            if argument.label?.text == "suiteName" {
                if let stringLiteral = argument.expression.as(
                    StringLiteralExprSyntax.self
                ) {
                    return stringLiteral.segments.first?.as(
                        StringSegmentSyntax.self
                    )?.content.text
                }
            }
        }

        return nil  // Default to nil if suiteName not found
    }

}
