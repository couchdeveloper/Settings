import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `@Settings` container macro
///
/// This macro generates the prefix property for a container type.
/// The container must manually conform to `__Settings_Container`.
public struct SettingsMacro: MemberMacro, ExtensionMacro {

    struct Attributes {
        var prefix: String
        var suiteName: String?
    }

    // MARK: - MemberMacro Implementation

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {

        // We only need this of we implement ObservableStore / ObservableAttribute
        // // Generate property `tokens`:
        // let tokensDecl: DeclSyntax = """
        // private let tokens = TokenStore<Store.ObservationToken>()
        // """
        //
        // return [tokensDecl]
        return []
    }

    // MARK: Extension Macro Implementation

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

        // Extract the prefix and suiteName from the macro arguments
        let prefix = try extractPrefix(from: node)
        try validatePrefix(prefix)
        let suiteName = try extractSuiteName(from: node)

        // Generate the static prefix property
        let prefixProperty = MemberBlockItemSyntax(
            decl: VariableDeclSyntax(
                modifiers: [
                    DeclModifierSyntax(name: .keyword(.public)),
                    DeclModifierSyntax(name: .keyword(.static)),
                ],
                bindingSpecifier: .keyword(.let),
                bindings: PatternBindingListSyntax([
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(
                            identifier: .identifier("prefix")
                        ),
                        typeAnnotation: TypeAnnotationSyntax(
                            type: IdentifierTypeSyntax(
                                name: .identifier("String")
                            )
                        ),
                        initializer: InitializerClauseSyntax(
                            value: StringLiteralExprSyntax(content: prefix)
                        )
                    )
                ])
            )
        )

        // Generate the static suiteName property
        let suiteNameProperty = MemberBlockItemSyntax(
            decl: VariableDeclSyntax(
                modifiers: [
                    DeclModifierSyntax(name: .keyword(.public)),
                    DeclModifierSyntax(name: .keyword(.static)),
                ],
                bindingSpecifier: .keyword(.let),
                bindings: PatternBindingListSyntax([
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(
                            identifier: .identifier("suiteName")
                        ),
                        typeAnnotation: TypeAnnotationSyntax(
                            type: OptionalTypeSyntax(
                                wrappedType: IdentifierTypeSyntax(
                                    name: .identifier("String")
                                )
                            )
                        ),
                        initializer: InitializerClauseSyntax(
                            value: suiteName != nil
                                ? ExprSyntax(
                                    StringLiteralExprSyntax(content: suiteName!)
                                )
                                : ExprSyntax(NilLiteralExprSyntax())
                        )
                    )
                ])
            )
        )

        // Check if the type already has prefix or suiteName properties defined
        let hasExistingPrefix = hasExistingProperty(
            named: "prefix",
            in: declaration
        )
        let hasExistingSuiteName = hasExistingProperty(
            named: "suiteName",
            in: declaration
        )

        // Only add properties that don't already exist
        var members: [MemberBlockItemSyntax] = []
        if !hasExistingPrefix {
            members.append(prefixProperty)
        }
        if !hasExistingSuiteName {
            members.append(suiteNameProperty)
        }

        // Generate an extension that adds conformance to __Settings_Container
        // and includes only the missing properties
        let extensionDecl = ExtensionDeclSyntax(
            extensionKeyword: .keyword(.extension),
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax {
                InheritedTypeSyntax(
                    type: IdentifierTypeSyntax(name: .identifier("__Settings_Container"))
                )
            },
            memberBlock: MemberBlockSyntax(
                members: MemberBlockItemListSyntax(members)
            )
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

    /// Check if a type declaration already has a property with the given name
    private static func hasExistingProperty(
        named propertyName: String,
        in declaration: some DeclGroupSyntax
    ) -> Bool {
        // Check the member list for existing properties
        for member in declaration.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(
                        IdentifierPatternSyntax.self
                    ),
                        identifier.identifier.text == propertyName
                    {
                        return true
                    }
                }
            }
        }
        return false
    }

    /// Extracts the prefix parameter from the macro arguments
    private static func extractPrefix(from node: AttributeSyntax) throws
        -> String
    {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self)
        else {
            return ""  // Default to empty prefix if no arguments
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

        return ""  // Default to empty prefix
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

    /// Gets the container type name from the declaration
    private static func getContainerTypeName(
        from declaration: some DeclGroupSyntax
    ) throws -> String {
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return structDecl.name.text
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            return classDecl.name.text
        } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            return enumDecl.name.text
        } else if let actorDecl = declaration.as(ActorDeclSyntax.self) {
            return actorDecl.name.text
        } else {
            throw MacroError.invalidContainerType
        }
    }
}
