import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct SimpleDiagnosticMessage: DiagnosticMessage {
    var diagnosticID: SwiftDiagnostics.MessageID
    let message: String
    let severity: DiagnosticSeverity
    var messageID: MessageID {
        MessageID(domain: "SettingMacro", id: message)
    }
}

/// Implementation of the `@Setting` macro
public struct SettingMacro: AccessorMacro, PeerMacro {

    // MARK: - AccessorMacro Implementation

    // Add getter and setter to the declaration

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.first,
            let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?
                .identifier
        else {
            throw MacroError.invalidDeclaration
        }

        let userDefaultPropertyName = identifier.text
        let userDefaultValueType = try valueType(from: binding)
        let providerDirective = determineEncodingProviderDirective(
            from: node,
            in: context
        )

        if shouldRejectCustomEncoding(
            for: userDefaultValueType,
            providerDirective: providerDirective,
            node: node,
            in: context,
            emitDiagnostic: false
        ) {
            return []
        }

        // The "attribute" name is the name of the enum symbol representing the
        // "__Attribute" of this Setting declaration. Here, we need only the
        // name of this enum. The attribute declaration itself will be generated
        // in another expansion function.
        let attributeTypeName = try generateAttributeTypeName(
            for: varDecl,
            propertyName: userDefaultPropertyName,
            in: context
        )

        // Generate the getter and setter for this UserDefault property
        let getter: AccessorDeclSyntax
        let setter: AccessorDeclSyntax

        getter = AccessorDeclSyntax(
            accessorSpecifier: .keyword(.get)
        ) {
            "return \(raw: attributeTypeName).read()"
        }

        setter = AccessorDeclSyntax(
            accessorSpecifier: .keyword(.set)
        ) {
            "\(raw: attributeTypeName).write(value: newValue)"
        }

        return [getter, setter]
    }

    // MARK: - PeerMacro Implementation

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.first,
            let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?
                .identifier
        else {
            throw MacroError.invalidDeclaration
        }

        let userDefaultPropertyName = identifier.text
        let containerType = try findContainerType(for: varDecl, in: context)
        // Try to extract container attributes (prefix/suiteName). If not found
        // (for example when the property is declared inside an extension) fall
        // back to an empty prefix and nil suiteName. Runtime methods will handle
        // prefix concatenation, so compile-time absence of the attribute is ok.
        let containerAttributes: SettingsMacro.Attributes
        do {
            containerAttributes = try extractContainerAttributes(
                for: varDecl,
                in: context
            )
        } catch MacroError.noContainerFound {
            containerAttributes = SettingsMacro.Attributes(
                prefix: "",
                suiteName: nil
            )
        }
        let userDefaultValueType = try valueType(from: binding)
        let encodingProviderDirective = determineEncodingProviderDirective(
            from: node,
            in: context
        )

        // FixIt Encoding if applicable
        if shouldRejectCustomEncoding(
            for: userDefaultValueType,
            providerDirective: encodingProviderDirective,
            node: node,
            in: context,
            emitDiagnostic: true
        ) {
            return []
        }

        let attributeTypeName = try generateAttributeTypeName(
            for: varDecl,
            propertyName: userDefaultPropertyName,
            in: context
        )
        let attributeQualifiedName = try generateAttributeQualifiedName(
            of: node,
            for: varDecl,
            propertyName: userDefaultPropertyName,
            prefix: containerAttributes.prefix ?? "",
            in: context
        )

        // Validate initial value requirements
        try validateInitialValue(
            binding: binding,
            isOptional: userDefaultValueType.isOptional
        )

        // Build the attribute enum declaration
        let enumDecl = buildAttributeEnum(
            propertyName: userDefaultPropertyName,
            attributeTypeName: attributeTypeName,
            containerTypeName: containerType,
            valueTypeName: userDefaultValueType,
            encodingProviderDirective: encodingProviderDirective,
            qualifiedName: attributeQualifiedName,
            hasDefaultValue: binding.initializer != nil,
            defaultValueExpr: binding.initializer?.value
        )

        // Generate projected value property ($propertyName)
        let projectedPropertyName = "$\(userDefaultPropertyName)"

        // Check if the original property is static to make the projected value static as well
        var projectedModifiers = [
            DeclModifierSyntax(name: .keyword(.public))
        ]
        let isStaticProperty = varDecl.modifiers.contains(where: { modifier in
            modifier.name.tokenKind == .keyword(.static)
        })
        if isStaticProperty {
            projectedModifiers.append(
                DeclModifierSyntax(name: .keyword(.static))
            )
        }

        let projectedProperty = VariableDeclSyntax(
            modifiers: DeclModifierListSyntax(projectedModifiers),
            bindingSpecifier: .keyword(.var),
            bindings: PatternBindingListSyntax([
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(
                        identifier: .identifier(projectedPropertyName)
                    ),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: IdentifierTypeSyntax(
                            name: .identifier(
                                "__AttributeProxy<\(attributeTypeName)>"
                            )
                        )
                    ),
                    accessorBlock: AccessorBlockSyntax(
                        accessors: .getter([
                            "return __AttributeProxy(attributeType: \(raw: attributeTypeName).self)"
                        ])
                    )
                )
            ])
        )

        return [DeclSyntax(enumDecl), DeclSyntax(projectedProperty)]
    }

}

// MARK: - __Attribute Enum Building Helpers

extension SettingMacro {
    /// Builds the complete attribute enum declaration for a @Setting property.
    ///
    /// Constructs a private enum conforming to __Attribute with computed type members,
    /// key property, optional default value, and encoder/decoder properties based on directives.
    private static func buildAttributeEnum(
        propertyName: String,
        attributeTypeName: String,
        containerTypeName: String,
        valueTypeName: ParsedValueType,
        encodingProviderDirective: EncodingProviderSelection,
        qualifiedName: String,
        hasDefaultValue: Bool,
        defaultValueExpr: ExprSyntax?
    ) -> EnumDeclSyntax {
        var members: [MemberBlockItemSyntax] = []
        members.append(makeContainerTypealias(containerType: containerTypeName))
        members.append(makeValueTypealias(valueType: valueTypeName))

        // For Optional types, add explicit Wrapped typealias
        if valueTypeName.isOptional,
            let wrappedTypealias = makeWrappedTypealias(
                valueType: valueTypeName
            )
        {
            members.append(wrappedTypealias)
        }

        // Add key pr
        members.append(makeNameProperty(attributeQualifiedName: qualifiedName))

        if !valueTypeName.isOptional {
            if let defaultProp = makeDefaultValueProperty(
                valueType: valueTypeName,
                defaultValueExpr: defaultValueExpr
            ) {
                members.append(defaultProp)
                members.append(makeDefaultRegistrarProperty())
            }
        }

        members.append(
            contentsOf: makeEncoderProperties(
                providerDirective: encodingProviderDirective
            )
        )

        return EnumDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .identifier(attributeTypeName),
            inheritanceClause: InheritanceClauseSyntax {
                InheritedTypeSyntax(
                    type: IdentifierTypeSyntax(
                        name: valueTypeName.isOptional
                            ? "__AttributeOptional" : "__AttributeNonOptional"
                    )
                )
            },
            memberBlock: MemberBlockSyntax(
                members: MemberBlockItemListSyntax(members)
            )
        )
    }

    /// Creates the `typealias Container = __ContainerResolver<BaseType>` member for the attribute enum.
    /// This uses conditional conformance to select either the base container (if it conforms to __Settings_Container)
    /// or provides a default implementation with UserDefaults.standard.
    private static func makeContainerTypealias(containerType: String)
        -> MemberBlockItemSyntax
    {
        // Generate: typealias Container = __ContainerResolver<BaseType>
        let containerResolverType = "__ContainerResolver<\(containerType)>"
        
        return MemberBlockItemSyntax(
            decl: TypeAliasDeclSyntax(
                modifiers: [DeclModifierSyntax(name: .keyword(.public))],
                name: "Container",
                initializer: TypeInitializerClauseSyntax(
                    value: TypeSyntax(stringLiteral: containerResolverType)
                )
            )
        )
    }

    /// Creates the `typealias Value = <ValueType>` member for the attribute enum.
    private static func makeValueTypealias(valueType: ParsedValueType)
        -> MemberBlockItemSyntax
    {
        MemberBlockItemSyntax(
            decl: TypeAliasDeclSyntax(
                modifiers: [DeclModifierSyntax(name: .keyword(.public))],
                name: "Value",
                initializer: TypeInitializerClauseSyntax(
                    value: IdentifierTypeSyntax(
                        name: .identifier(valueType.name)
                    )
                )
            )
        )
    }

    /// Creates the `typealias Wrapped = <UnwrappedType>` member for Optional value types.
    /// This is required because extensions have explicit `Wrapped == T` constraints for `Value == Optional<T>`.
    private static func makeWrappedTypealias(valueType: ParsedValueType)
        -> MemberBlockItemSyntax?
    {
        guard valueType.isOptional else { return nil }

        // Extract the unwrapped type from the Optional
        let unwrappedTypeName: String
        if let syntax = valueType.syntax {
            // Try to extract from AST
            if let optionalType = syntax.as(OptionalTypeSyntax.self) {
                // Handle "T?" syntax
                unwrappedTypeName = optionalType.wrappedType.trimmedDescription
            } else if let identifierType = syntax.as(IdentifierTypeSyntax.self),
                let genericArgs = identifierType.genericArgumentClause?
                    .arguments.first
            {
                // Handle "Optional<T>" or "Swift.Optional<T>" syntax
                unwrappedTypeName = genericArgs.argument.trimmedDescription
            } else {
                // Fallback to string parsing
                unwrappedTypeName = extractUnwrappedTypeFromString(
                    valueType.name
                )
            }
        } else {
            // No AST available, use string parsing
            unwrappedTypeName = extractUnwrappedTypeFromString(valueType.name)
        }

        return MemberBlockItemSyntax(
            decl: TypeAliasDeclSyntax(
                modifiers: [DeclModifierSyntax(name: .keyword(.public))],
                name: "Wrapped",
                initializer: TypeInitializerClauseSyntax(
                    value: IdentifierTypeSyntax(
                        name: .identifier(unwrappedTypeName)
                    )
                )
            )
        )
    }

    /// Extracts the unwrapped type name from an Optional type string.
    /// "String?" -> "String", "Optional<String>" -> "String", "Swift.Optional<Int>" -> "Int"
    private static func extractUnwrappedTypeFromString(_ typeName: String)
        -> String
    {
        if typeName.hasSuffix("?") {
            // Handle "T?" syntax
            return String(typeName.dropLast())
        } else if typeName.contains("<") && typeName.hasSuffix(">") {
            // Handle "Optional<T>" or "Swift.Optional<T>" syntax
            if let startIndex = typeName.firstIndex(of: "<"),
                let endIndex = typeName.lastIndex(of: ">")
            {
                let innerType = typeName[
                    typeName.index(after: startIndex)..<endIndex
                ]
                return String(innerType)
            }
        }
        // Fallback: return as-is (shouldn't happen for valid Optional types)
        return typeName
    }

    /// Creates the `static let name = "..."` property which is used to compose a
    /// UserDefaults key.
    /// The `name` stored property returs the qualified name of the Attribute, not inlcuding the prefix
    /// of the container. The `key` property is a computed property which returns:
    /// `Container.prefix + name`.
    private static func makeNameProperty(attributeQualifiedName: String)
        -> MemberBlockItemSyntax
    {
        MemberBlockItemSyntax(
            decl: VariableDeclSyntax(
                modifiers: [
                    DeclModifierSyntax(name: .keyword(.public)),
                    DeclModifierSyntax(name: .keyword(.static)),
                ],
                bindingSpecifier: .keyword(.let),
                bindings: PatternBindingListSyntax([
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(
                            identifier: .identifier("name")
                        ),
                        initializer: InitializerClauseSyntax(
                            value: StringLiteralExprSyntax(
                                content: attributeQualifiedName
                            )
                        )
                    )
                ])
            )
        )
    }

    /// Creates the optional `static var defaultValue: Value { ... }` property if a default is specified.
    /// Returns nil if no default value is provided.
    private static func makeDefaultValueProperty(
        valueType: ParsedValueType,
        defaultValueExpr: ExprSyntax?
    ) -> MemberBlockItemSyntax? {
        guard !valueType.isOptional, let defaultValue = defaultValueExpr else {
            return nil
        }
        return MemberBlockItemSyntax(
            decl: VariableDeclSyntax(
                modifiers: [
                    DeclModifierSyntax(name: .keyword(.public)),
                    DeclModifierSyntax(name: .keyword(.static)),
                ],
                bindingSpecifier: .keyword(.let),
                bindings: PatternBindingListSyntax([
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(
                            identifier: .identifier("defaultValue")
                        ),
                        typeAnnotation: TypeAnnotationSyntax(
                            type: IdentifierTypeSyntax(
                                name: .identifier(valueType.name)
                            )
                        ),
                        initializer: InitializerClauseSyntax(
                            value: defaultValue
                        )
                    )
                ])
            )
        )
    }

    /// Creates the `static let defaultRegistrar = __DefaultRegistrar()` member used to register defaults at load time.
    private static func makeDefaultRegistrarProperty() -> MemberBlockItemSyntax
    {
        MemberBlockItemSyntax(
            decl: VariableDeclSyntax(
                modifiers: [
                    DeclModifierSyntax(name: .keyword(.public)),
                    DeclModifierSyntax(name: .keyword(.static)),
                ],
                bindingSpecifier: .keyword(.let),
                bindings: PatternBindingListSyntax([
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(
                            identifier: .identifier("defaultRegistrar")
                        ),
                        initializer: InitializerClauseSyntax(
                            value: ExprSyntax(
                                stringLiteral: "__DefaultRegistrar()"
                            )
                        )
                    )
                ])
            )
        )
    }

    /// Creates encoder/decoder properties based on the encoding directive (strategy or custom).
    /// Returns empty array for property-list types that don't need custom encoding.
    private static func makeEncoderProperties(
        providerDirective: EncodingProviderSelection
    ) -> [MemberBlockItemSyntax] {
        switch providerDirective {
        case .custom(let encoderExpr, let decoderExpr):
            return [
                makeCoderProperty(
                    name: "encoder",
                    typeDescription: "some AttributeEncoding",
                    expression: encoderExpr
                ),
                makeCoderProperty(
                    name: "decoder",
                    typeDescription: "some AttributeDecoding",
                    expression: decoderExpr
                ),
            ]
        case .strategy(let strategy):
            return [
                makeCoderProperty(
                    name: "encoder",
                    typeDescription: "some AttributeEncoding",
                    expression: strategy.encoderExpression
                ),
                makeCoderProperty(
                    name: "decoder",
                    typeDescription: "some AttributeDecoding",
                    expression: strategy.decoderExpression
                ),
            ]
        case .none:
            return []
        }
    }

    /// Creates a single encoder or decoder property member with the specified name and value expression.
    private static func makeCoderProperty(
        name: String,
        typeDescription: String,
        expression: ExprSyntax
    ) -> MemberBlockItemSyntax {
        MemberBlockItemSyntax(
            decl: VariableDeclSyntax(
                modifiers: [
                    DeclModifierSyntax(name: .keyword(.public)),
                    DeclModifierSyntax(name: .keyword(.static)),
                ],
                bindingSpecifier: .keyword(.var),
                bindings: PatternBindingListSyntax([
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(
                            identifier: .identifier(name)
                        ),
                        typeAnnotation: TypeAnnotationSyntax(
                            type: TypeSyntax(stringLiteral: typeDescription)
                        ),
                        accessorBlock: AccessorBlockSyntax(
                            accessors: .getter([
                                "return \(raw: expression.trimmedDescription)"
                            ])
                        )
                    )
                ])
            )
        )
    }
}

// MARK: - Helper Methods

extension SettingMacro {

    private enum EncodingStrategy: String {
        case json
        case plist

        var encoderExpression: ExprSyntax {
            switch self {
            case .json:
                return ExprSyntax(stringLiteral: "JSONEncoder()")
            case .plist:
                return ExprSyntax(stringLiteral: "PropertyListEncoder()")
            }
        }

        var decoderExpression: ExprSyntax {
            switch self {
            case .json:
                return ExprSyntax(stringLiteral: "JSONDecoder()")
            case .plist:
                return ExprSyntax(stringLiteral: "PropertyListDecoder()")
            }
        }
    }

    private enum EncodingProviderSelection {
        case none
        case strategy(EncodingStrategy)
        case custom(encoder: ExprSyntax, decoder: ExprSyntax)
    }

    private static func parseEncodingStrategy(from expr: ExprSyntax)
        -> EncodingStrategy?
    {
        if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
            return EncodingStrategy(
                rawValue: memberAccess.declName.baseName.text
            )
        }
        if let declRef = expr.as(DeclReferenceExprSyntax.self) {
            return EncodingStrategy(rawValue: declRef.baseName.text)
        }
        return nil
    }

    private struct ProviderExpressions {
        let encoder: ExprSyntax?
        let decoder: ExprSyntax?
        let encoding: ExprSyntax?
    }

    private static func extractProviderExpressions(from node: AttributeSyntax)
        -> ProviderExpressions
    {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self)
        else {
            return ProviderExpressions(
                encoder: nil,
                decoder: nil,
                encoding: nil
            )
        }
        var encoderExpr: ExprSyntax?
        var decoderExpr: ExprSyntax?
        var encodingExpr: ExprSyntax?
        for argument in arguments {
            switch argument.label?.text {
            case "encoder":
                encoderExpr = argument.expression
            case "decoder":
                decoderExpr = argument.expression
            case "encoding":
                encodingExpr = argument.expression
            default:
                break
            }
        }
        return ProviderExpressions(
            encoder: encoderExpr,
            decoder: decoderExpr,
            encoding: encodingExpr
        )
    }

    /// Determines which encoding provider (if any) is specified in the @Setting attribute.
    /// Returns .strategy for `encoding: .json/.plist`, .custom for explicit encoder/decoder, or .none.
    private static func determineEncodingProviderDirective(
        from node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) -> EncodingProviderSelection {
        let providers = extractProviderExpressions(from: node)

        if let encodingExpr = providers.encoding {
            if providers.encoder != nil || providers.decoder != nil {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(node),
                        message: SimpleDiagnosticMessage(
                            diagnosticID: .init(
                                domain:
                                    "swift-corelibs-foundation-userdefaults-macro-invalid-providers",
                                id: "invalid_mixed_encoding"
                            ),
                            message:
                                "Use either `encoding` or explicit `encoder`/`decoder`, not both.",
                            severity: .error
                        )
                    )
                )
                return .none
            }
            if let strategy = Self.parseEncodingStrategy(from: encodingExpr) {
                return .strategy(strategy)
            }
            context.diagnose(
                Diagnostic(
                    node: Syntax(encodingExpr),
                    message: SimpleDiagnosticMessage(
                        diagnosticID: .init(
                            domain:
                                "swift-corelibs-foundation-userdefaults-macro-invalid-providers",
                            id: "invalid_encoding_strategy"
                        ),
                        message:
                            "Unknown encoding strategy. Use `.json` or `.plist`.",
                        severity: .error
                    )
                )
            )
            return .none
        }

        if let encoderExpr = providers.encoder,
            let decoderExpr = providers.decoder
        {
            return .custom(encoder: encoderExpr, decoder: decoderExpr)
        }

        if (providers.encoder == nil) != (providers.decoder == nil) {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: SimpleDiagnosticMessage(
                        diagnosticID: .init(
                            domain:
                                "swift-corelibs-foundation-userdefaults-macro-invalid-providers",
                            id: "invalid_providers"
                        ),
                        message:
                            "Provide both `encoder` and `decoder`, or neither.",
                        severity: .error
                    )
                )
            )
        }

        return .none
    }

    /// Returns true if custom encoding was specified for a property-list-compatible type.
    /// Property-list types (Bool, Int, String, etc.) already store natively and don't need custom coders.
    /// If emitDiagnostic is true, also generates a diagnostic with a Fix-It to remove the encoding argument.
    private static func shouldRejectCustomEncoding(
        for valueType: ParsedValueType,
        providerDirective: EncodingProviderSelection,
        node: AttributeSyntax,
        in context: some MacroExpansionContext,
        emitDiagnostic: Bool
    ) -> Bool {
        if case .none = providerDirective {
            return false
        }
        guard isPropertyListCompatibleType(valueType) else {
            return false
        }

        if emitDiagnostic {
            var fixIts: [FixIt] = []
            if let fixIt = makeEncodingRemovalFixIt(
                in: node,
                providerDirective: providerDirective
            ) {
                fixIts = [fixIt]
            }

            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: SimpleDiagnosticMessage(
                        diagnosticID: .init(
                            domain:
                                "swift-corelibs-foundation-userdefaults-macro-invalid-providers",
                            id: "unsupported_propertylist_encoding"
                        ),
                        message:
                            "`encoding`/`encoder` arguments are only supported for Codable types. `\(valueType.name)` already stores natively in UserDefaults.",
                        severity: .error
                    ),
                    fixIts: fixIts
                )
            )
        }

        return true
    }

    /// Builds a Fix-It that removes encoding/decoding arguments from the @Setting attribute.
    /// Handles both `encoding: .strategy` and explicit `encoder:/decoder:` cases, preserving other arguments.
    private static func makeEncodingRemovalFixIt(
        in attribute: AttributeSyntax,
        providerDirective: EncodingProviderSelection
    ) -> FixIt? {
        let labelsToRemove: [String]
        let message: String

        switch providerDirective {
        case .strategy:
            labelsToRemove = ["encoding"]
            message = "Remove the `encoding` argument for property-list values."
        case .custom:
            labelsToRemove = ["encoder", "decoder"]
            message =
                "Remove the `encoder` and `decoder` arguments for property-list values."
        case .none:
            return nil
        }

        guard
            let updatedAttribute = attributeByRemovingArguments(
                labelsToRemove,
                from: attribute
            )
        else {
            return nil
        }

        return FixIt(
            message: MacroExpansionFixItMessage(message),
            changes: [
                .replace(
                    oldNode: Syntax(attribute),
                    newNode: Syntax(updatedAttribute)
                )
            ]
        )
    }

    private static func attributeByRemovingArguments(
        _ labelsToRemove: [String],
        from attribute: AttributeSyntax
    ) -> AttributeSyntax? {
        guard
            let argumentList = attribute.arguments?.as(
                LabeledExprListSyntax.self
            ), !labelsToRemove.isEmpty
        else {
            return nil
        }

        let labels = Set(labelsToRemove)
        let keptElements: [LabeledExprSyntax] = argumentList.filter {
            argument in
            guard let label = argument.label?.text else { return true }
            return !labels.contains(label)
        }.map { $0 }

        if keptElements.isEmpty {
            var updated =
                attribute
                .with(\.arguments, nil)
                .with(\.leftParen, nil)
                .with(\.rightParen, nil)
            // Ensure there is a token separator after `@Setting` when we drop parentheses
            if var idType = updated.attributeName.as(IdentifierTypeSyntax.self)
            {
                // Add a single space as trailing trivia to the identifier token
                let spacedName = idType.name.with(\.trailingTrivia, .spaces(1))
                idType = idType.with(\.name, spacedName)
                updated = updated.with(\.attributeName, TypeSyntax(idType))
            }
            return updated
        } else {
            var adjustedElements = keptElements
            if let lastIndex = adjustedElements.indices.last {
                adjustedElements[lastIndex] = adjustedElements[lastIndex].with(
                    \.trailingComma,
                    nil
                )
            }
            let newList = LabeledExprListSyntax(adjustedElements)
            return attribute.with(\.arguments, .argumentList(newList))
        }
    }

    /// Walks up the lexical context to find the nearest type conforming to `__Settings_Container`.
    /// Returns the qualified type name (e.g., "AppSettings.UserSettings").
    private static func findContainerType(
        for varDecl: VariableDeclSyntax,
        in context: some MacroExpansionContext
    ) throws -> String {

        func isAnnotatedWithUserDefaultsMacro(
            _ attributes: SwiftSyntax.AttributeListSyntax
        ) -> Bool {
            for attr in attributes {
                guard let attribute = attr.as(AttributeSyntax.self) else {
                    continue
                }
                // __Attribute name may be an identifier type (UserDefaults)
                if let idType = attribute.attributeName.as(
                    IdentifierTypeSyntax.self
                ), idType.name.text == "Settings" {
                    return true
                }
            }
            return false
        }

        // Walk up the container type hierarchy and find the first type
        // which is a store Container (aka `__Settings_Container`)
        var topContainer: String = ""
        var inExtension = false
        
        for contextNode in context.lexicalContext {
            if let extensionDecl = contextNode.as(ExtensionDeclSyntax.self) {
                inExtension = true
                let fullTypeName = extensionDecl.extendedType.description
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                topContainer =
                    fullTypeName.components(separatedBy: ".").first
                    ?? fullTypeName
                if isAnnotatedWithUserDefaultsMacro(extensionDecl.attributes) {
                    // Extract root container name (e.g., "AppSettings.UserSettings" -> "AppSettings")
                    return fullTypeName.components(separatedBy: ".").first
                        ?? fullTypeName
                }
            }
            if let structDecl = contextNode.as(StructDeclSyntax.self) {
                if topContainer.isEmpty {
                    topContainer = structDecl.name.text
                }
                if isAnnotatedWithUserDefaultsMacro(structDecl.attributes) {
                    return structDecl.name.text
                }
            }
            if let classDecl = contextNode.as(ClassDeclSyntax.self) {
                if topContainer.isEmpty {
                    topContainer = classDecl.name.text
                }
                if isAnnotatedWithUserDefaultsMacro(classDecl.attributes) {
                    return classDecl.name.text
                }
            }
            if let enumDecl = contextNode.as(EnumDeclSyntax.self) {
                if topContainer.isEmpty {
                    topContainer = enumDecl.name.text
                }
                if isAnnotatedWithUserDefaultsMacro(enumDecl.attributes) {
                    return enumDecl.name.text
                }
            }
            if let actorDecl = contextNode.as(ActorDeclSyntax.self) {
                if topContainer.isEmpty {
                    topContainer = actorDecl.name.text
                }
                if isAnnotatedWithUserDefaultsMacro(actorDecl.attributes) {
                    return actorDecl.name.text
                }
            }
        }

        // If we're in an extension or found a top container name, return it
        // The type system will resolve whether it's a __Settings_Container via __ContainerResolver
        if !topContainer.isEmpty {
            return topContainer
        }

        // No container found at all - this shouldn't happen in valid Swift code
        throw MacroError.noContainerFound
    }

    /// Returns the containers attributes.
    ///
    /// - Parameters:
    ///   - declaration: The `UserDefault` declaration.
    ///   - context: The context where the UserDefault resides.
    /// - Returns: The prefix for the container, where the Setting declaration resides in.
    private static func extractContainerAttributes(
        for varDecl: VariableDeclSyntax,
        in context: some MacroExpansionContext
    ) throws -> SettingsMacro.Attributes {
        // Returns nil if the given attributes don't contain any attribute which is
        // a `@UserDefaults` macro. Otherwise returns the node which declares it.
        func findNodeAnnotatedWithUserDefaultsMacro(
            _ attributes: SwiftSyntax.AttributeListSyntax
        ) -> SwiftSyntax.AttributeSyntax? {
            for attr in attributes {
                guard let attribute = attr.as(AttributeSyntax.self) else {
                    continue
                }
                // __Attribute name may be an identifier type (UserDefaults)
                if let idType = attribute.attributeName.as(
                    IdentifierTypeSyntax.self
                ), idType.name.text == "Settings" {
                    return attribute
                }
            }
            return nil
        }

        for contextNode in context.lexicalContext {
            // If any enclosing node is a type declaration annotated with @UserDefaults,
            // treat that type as the container and return its name directly. This allows
            // the inner @Setting macro to determine the container type even when
            // the @Settings macro hasn't yet emitted the extension that adds
            // conformance to `__Settings_Container`.
            if let extensionDecl = contextNode.as(ExtensionDeclSyntax.self) {
                if let node = findNodeAnnotatedWithUserDefaultsMacro(
                    extensionDecl.attributes
                ) {
                    return try SettingsMacro.extractAttributes(from: node)
                }
            }
            if let structDecl = contextNode.as(StructDeclSyntax.self) {
                if let node = findNodeAnnotatedWithUserDefaultsMacro(
                    structDecl.attributes
                ) {
                    return try SettingsMacro.extractAttributes(from: node)
                }
            }
            if let classDecl = contextNode.as(ClassDeclSyntax.self) {
                if let node = findNodeAnnotatedWithUserDefaultsMacro(
                    classDecl.attributes
                ) {
                    return try SettingsMacro.extractAttributes(from: node)
                }
            }
            if let enumDecl = contextNode.as(EnumDeclSyntax.self) {
                if let node = findNodeAnnotatedWithUserDefaultsMacro(
                    enumDecl.attributes
                ) {
                    return try SettingsMacro.extractAttributes(from: node)
                }
            }
            if let actorDecl = contextNode.as(ActorDeclSyntax.self) {
                if let node = findNodeAnnotatedWithUserDefaultsMacro(
                    actorDecl.attributes
                ) {
                    return try SettingsMacro.extractAttributes(from: node)
                }
            }
        }
        throw MacroError.noContainerFound
    }

    /// Generates the partial key for this attribute from its qualified path + property name.
    /// The container prefix is NOT included - it will be added at runtime via the protocol extension.
    /// Example: path=["Settings", "User"] + property="theme" → "Settings::User::theme"
    private static func generateAttributeQualifiedName(
        of node: SwiftSyntax.AttributeSyntax,
        for varDecl: SwiftSyntax.VariableDeclSyntax,
        propertyName: String,
        prefix: String,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> String {
        // TODO: we don't have the module name yet!
        func extractCustomKeyName(from node: AttributeSyntax) -> String? {
            guard let arguments = node.arguments?.as(LabeledExprListSyntax.self)
            else {
                return nil
            }
            for argument in arguments {
                if argument.label?.text == "name",
                    let stringLiteral = argument.expression.as(
                        StringLiteralExprSyntax.self
                    )
                {
                    return stringLiteral.segments.first?.as(
                        StringSegmentSyntax.self
                    )?.content.text
                }
            }
            return nil
        }

        let keyName = extractCustomKeyName(from: node)
        if let keyName {
            return keyName
        }
        return try generateKeyName(
            for: varDecl,
            propertyName: propertyName,
            moduleName: "",
            prefix: prefix,
            in: context
        )
    }

    /// Returns the name of the attribute for the given Setting declaration.
    ///
    /// For each Setting declaration, the macro must generate a corresponding __Attribute
    /// declaration. This function does not generate the Atrtibute declaration, it only returns
    /// the symbol name of it.
    ///
    /// ## Further info:
    /// The attribute needs to be declared private in the top level of the module. The
    /// symbol name must be unique and thus, it uses the qualified name (not includig the
    /// module name) of the declaration of `propertyName` with a prefix: `"__Attribute_"`.
    ///
    /// The location of the Setting declaration also needs to be inside a container type
    /// which conforms to `_UserDefaultContainer`. The container doesn't need to be the
    /// first enclosing container though, it can be any parent. The found type which conforms to
    /// `_UserDefaultContainer` must itself NOT be contained in another container conforming to
    /// `_UserDefaultContainer`. In order to find the first container which is a `__Settings_Container`
    /// we need to walk up the container hierarchy in order to find it. The given parameter `context`
    /// has exactly this information.
    private static func generateAttributeTypeName(
        for declaration: SwiftSyntax.VariableDeclSyntax,
        propertyName: String,
        in context: some MacroExpansionContext
    ) throws -> String {
        let qualifiedName = try generateQualifiedName(for: context).joined(
            separator: "_"
        )
        return "__Attribute_\(qualifiedName)_\(propertyName)"
    }

    /// Returns the qualified name of a declaration whose context is given as parameter `context`.
    /// Walks the lexical context chain to build dot-separated type names (e.g., ["AppSettings", "UserSettings"]).
    /// Excludes the property name itself and the module name from the result.
    ///
    /// - Parameter context: The declaration context to generate the qualified name for
    /// - Returns: A string containing the qualified name, or an empty string if the declaration
    ///           is defined at the top level of a module
    private static func generateQualifiedName(
        for context: some MacroExpansionContext
    ) throws -> [String] {
        var components: [String] = []
        for contextNode in context.lexicalContext {
            if let extensionDecl = contextNode.as(ExtensionDeclSyntax.self) {
                let typeName = extensionDecl.extendedType.description
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                // Replace dots with underscores for valid identifier names
                let validTypeName = typeName.replacingOccurrences(
                    of: ".",
                    with: "_"
                )
                components.append(validTypeName)
                continue
            }
            if let structDecl = contextNode.as(StructDeclSyntax.self) {
                components.append(structDecl.name.text)
                continue
            }
            if let enumDecl = contextNode.as(EnumDeclSyntax.self) {
                components.append(enumDecl.name.text)
                continue
            }
            if let classDecl = contextNode.as(ClassDeclSyntax.self) {
                components.append(classDecl.name.text)
                continue
            }

            // Check for some invalid locations:
            if let funcDecl = contextNode.as(FunctionDeclSyntax.self) {
                let typeName = funcDecl.name.text
                throw MacroError.invalidEnclosingContainer(typeName)
            }

            let kind = "\(contextNode.kind)"
            throw MacroError.invalidEnclosingContainerDecl(kind)
        }
        components.reverse()
        return components
    }

    /// Returns the logical name for an `__Attribute` (without the container prefix).
    ///
    /// The container prefix is NOT included in the returned string. The prefix will be
    /// added at runtime by the protocol extension when computing the `key` property.
    ///
    /// - Parameters:
    ///   - varDecl: The Setting declaration.
    ///   - propertyName: The name of the property of the `Setting` declaration.
    ///   - moduleName: The name of the module where the `Setting` macro has been declared.
    ///   - prefix: A prefix defined in the container type (currently unused, reserved for future use).
    ///   - context: The context of the Setting declaration.
    /// - Returns: A logical key name like "Profile::setting" or just "setting" for top-level properties.
    private static func generateKeyName(
        for varDecl: VariableDeclSyntax,
        propertyName: String,
        moduleName: String?,
        prefix: String,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> String {
        // For nested types, include the namespace hierarchy in the name
        // e.g., AppSettings.UserSettings -> "UserSettings::setting"

        // Helper function to check if attributes contain @Settings macro
        func isAnnotatedWithUserDefaultsMacro(
            _ attributes: SwiftSyntax.AttributeListSyntax
        ) -> Bool {
            for attr in attributes {
                guard let attribute = attr.as(AttributeSyntax.self) else {
                    continue
                }
                // __Attribute name may be an identifier type (UserDefaults)
                if let idType = attribute.attributeName.as(
                    IdentifierTypeSyntax.self
                ), idType.name.text == "Settings" {
                    return true
                }
            }
            return false
        }

        // Collect all nested type names and the extension info
        // Lexical context is traversed from innermost to outermost
        var nestedTypeNames: [String] = []
        var extensionTypeName: String? = nil

        for contextNode in context.lexicalContext {
            // Check for nested type declarations (enum, struct, class)
            if let enumDecl = contextNode.as(EnumDeclSyntax.self) {
                // Only add if not annotated with @UserDefaults (not the container itself)
                if !isAnnotatedWithUserDefaultsMacro(enumDecl.attributes) {
                    nestedTypeNames.append(enumDecl.name.text)
                }
            } else if let structDecl = contextNode.as(StructDeclSyntax.self) {
                // Only add if not annotated with @UserDefaults (not the container itself)
                if !isAnnotatedWithUserDefaultsMacro(structDecl.attributes) {
                    nestedTypeNames.append(structDecl.name.text)
                }
            } else if let classDecl = contextNode.as(ClassDeclSyntax.self) {
                // Only add if not annotated with @UserDefaults (not the container itself)
                if !isAnnotatedWithUserDefaultsMacro(classDecl.attributes) {
                    nestedTypeNames.append(classDecl.name.text)
                }
            }
            // Check for extension
            else if let extensionDecl = contextNode.as(ExtensionDeclSyntax.self)
            {
                extensionTypeName = extensionDecl.extendedType.description
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                // Once we find the extension, we can stop
                break
            }
        }

        // Determine the namespace based on what we found
        if let extendedType = extensionTypeName {
            // If extending a nested type (AppSettings.Profile), use the nested part
            if let dotIndex = extendedType.firstIndex(of: ".") {
                let namespace = String(
                    extendedType[extendedType.index(after: dotIndex)...]
                )
                return "\(namespace)::\(propertyName)"
            }
            // If we have nested types inside a simple extension, use those
            if !nestedTypeNames.isEmpty {
                // Reverse because we collected from innermost to outermost
                let namespace = nestedTypeNames.reversed().joined(
                    separator: "::"
                )
                return "\(namespace)::\(propertyName)"
            }
        } else {
            // No extension, check if we have nested types (e.g., enum inside enum)
            if !nestedTypeNames.isEmpty {
                // Reverse because we collected from innermost to outermost
                // Skip the outermost container (the one that would have @Settings)
                let namespace = nestedTypeNames.dropLast().reversed().joined(
                    separator: "::"
                )
                if !namespace.isEmpty {
                    return "\(namespace)::\(propertyName)"
                }
            }
        }

        // Default: just use the property name
        return propertyName
    }

    /// Extracts the value type from a property binding.
    ///
    /// If an explicit type annotation is present, that type is used.
    /// If an initializer is present but no type annotation, the type is
    /// inferred. Otherwise, an error is thrown.
    ///
    /// - Parameters:
    ///   - binding: The syntax binding that contains the function declaration
    ///  and its parameters.
    ///   - context: The macro expansion context providing access to the
    ///  compilation environment and diagnostic capabilities.
    /// - Throws: MacroExpansionError if the syntax structure is invalid or if
    ///  required parameters are missing.
    /// - Returns: A string containing the generated documentation comment
    ///  formatted according to Swift documentation standards.
    private struct ParsedValueType {
        let name: String
        let isOptional: Bool
        let syntax: TypeSyntax?
    }

    private static func valueType(
        from binding: PatternBindingSyntax,
    ) throws -> ParsedValueType {
        func isOptionalType(_ type: TypeSyntax) -> Bool {
            // Handles "T?"
            if type.is(OptionalTypeSyntax.self) {
                return true
            }
            // Handles "Optional<T>" and "Swift.Optional<T>"
            if let simple = type.as(IdentifierTypeSyntax.self) {
                if simple.name.text == "Optional"
                    || simple.name.text == "Swift.Optional"
                {
                    return true
                }
            }
            return false
        }

        func inferTypeFromInitializer(_ initializer: InitializerClauseSyntax)
            throws -> String
        {
            let initializerExpr: ExprSyntax = initializer.value
            if initializerExpr.is(StringLiteralExprSyntax.self) {
                return "String"
            } else if initializerExpr.is(IntegerLiteralExprSyntax.self) {
                return "Int"
            } else if initializerExpr.is(FloatLiteralExprSyntax.self) {
                return "Double"
            } else if initializerExpr.is(BooleanLiteralExprSyntax.self) {
                return "Bool"
            } else if initializerExpr.is(ArrayExprSyntax.self) {
                return "Array<Any>"
            } else if initializerExpr.is(DictionaryExprSyntax.self) {
                return "Dictionary<String, Any>"
            } else {
                throw MacroError.cannotDetermineType
            }
        }

        if let typeAnnotation = binding.typeAnnotation {
            let type = typeAnnotation.type
            let typeName = type.description.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            let optional = isOptionalType(type)
            return ParsedValueType(
                name: typeName,
                isOptional: optional,
                syntax: type
            )
        } else if let initializer = binding.initializer {
            return ParsedValueType(
                name: try inferTypeFromInitializer(initializer),
                isOptional: false,
                syntax: nil
            )
        } else {
            throw MacroError.cannotDetermineType
        }
    }

    private static func isPropertyListCompatibleType(
        _ parsedType: ParsedValueType
    ) -> Bool {
        if let syntax = parsedType.syntax {
            return isPropertyListTypeSyntax(syntax)
        }
        return isPropertyListTypeName(parsedType.name)
    }

    private static func isPropertyListTypeSyntax(_ type: TypeSyntax) -> Bool {
        if let optional = type.as(OptionalTypeSyntax.self) {
            return isPropertyListTypeSyntax(optional.wrappedType)
        }
        if let implicitlyUnwrapped =
            type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self)
        {
            return isPropertyListTypeSyntax(implicitlyUnwrapped.wrappedType)
        }
        if let arrayType = type.as(ArrayTypeSyntax.self) {
            return isPropertyListTypeSyntax(arrayType.element)
        }
        if let dictType = type.as(DictionaryTypeSyntax.self) {
            return isStringType(dictType.key)
                && isPropertyListTypeSyntax(dictType.value)
        }
        if let memberType = type.as(MemberTypeSyntax.self) {
            if handlesCollectionType(
                name: memberType.name.text,
                genericArguments: memberType.genericArgumentClause
            ) {
                return true
            }
            return scalarPropertyListTypeNames.contains(
                memberType.name.text
            )
        }
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            if handlesCollectionType(
                name: identifier.name.text,
                genericArguments: identifier.genericArgumentClause
            ) {
                return true
            }
            return scalarPropertyListTypeNames.contains(identifier.name.text)
        }
        return false
    }

    private static func handlesCollectionType(
        name: String,
        genericArguments: GenericArgumentClauseSyntax?
    ) -> Bool {
        switch name {
        case "Optional", "Swift.Optional":
            if let argument =
                genericArguments?.arguments.first?.argument
            {
                return isPropertyListTypeSyntax(argument)
            }
            return false
        case "Array", "Swift.Array":
            if let argument =
                genericArguments?.arguments.first?.argument
            {
                return isPropertyListTypeSyntax(argument)
            }
            return false
        case "Dictionary", "Swift.Dictionary":
            guard let clause = genericArguments else {
                return false
            }
            let args = clause.arguments
            guard args.count == 2 else {
                return false
            }
            let firstIndex = args.startIndex
            let secondIndex = args.index(after: firstIndex)
            let key = args[firstIndex].argument
            let value = args[secondIndex].argument
            return isStringType(key)
                && isPropertyListTypeSyntax(value)
        default:
            return false
        }
    }

    private static func isStringType(_ type: TypeSyntax) -> Bool {
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            let name = identifier.name.text
            return name == "String" || name == "Swift.String"
        }
        if let member = type.as(MemberTypeSyntax.self) {
            let name = member.name.text
            return name == "String"
        }
        return false
    }

    private static func isPropertyListTypeName(_ rawName: String) -> Bool {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("?") {
            let inner = String(trimmed.dropLast())
            return isPropertyListTypeName(inner)
        }
        if trimmed.hasPrefix("Optional<"), trimmed.hasSuffix(">") {
            let inner = String(trimmed.dropFirst("Optional<".count).dropLast())
            return isPropertyListTypeName(inner)
        }
        if trimmed.hasPrefix("Swift.Optional<"), trimmed.hasSuffix(">") {
            let inner = String(
                trimmed.dropFirst("Swift.Optional<".count).dropLast()
            )
            return isPropertyListTypeName(inner)
        }
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            let inner = String(trimmed.dropFirst().dropLast())
            // Dictionary literal
            if let colonIndex = inner.firstIndex(of: ":") {
                let key = String(inner[..<colonIndex]).trimmingCharacters(
                    in: .whitespaces
                )
                let value = String(inner[inner.index(after: colonIndex)...])
                    .trimmingCharacters(in: .whitespaces)
                return isPropertyListTypeName(key)
                    && isPropertyListTypeName(value)
            }
            return isPropertyListTypeName(inner)
        }
        let simple =
            trimmed.split(separator: ".").last.map(String.init)
            ?? trimmed
        return scalarPropertyListTypeNames.contains(simple)
    }

    private static let scalarPropertyListTypeNames: Set<String> = [
        "Bool", "Int", "Double", "Float", "String", "Date", "Data",
        "URL", "Any",
    ]

    private static func validateInitialValue(
        binding: PatternBindingSyntax,
        isOptional: Bool
    ) throws {
        let hasInitialValue = binding.initializer != nil

        if !isOptional && !hasInitialValue {
            throw MacroError.missingInitialValue
        }

        if isOptional && hasInitialValue {
            throw MacroError.invalidInitialValue
        }
    }
}

// MARK: - Internal Helpers

protocol _Conformable {
    var _inheritanceClause: SwiftSyntax.InheritanceClauseSyntax? { get }
    var _typeName: String { get }
}

extension _Conformable {
    var _inheritanceClause: SwiftSyntax.InheritanceClauseSyntax? { nil }
    var _typeName: String {
        fatalError("Must be implemented in conforming types")
    }
}

extension _Conformable {
    func conforms(to protocolName: String, qualifiedName: String) -> Bool {
        guard let inheritanceClause = self._inheritanceClause else {
            return false
        }
        for inheritedType in inheritanceClause.inheritedTypes {
            let typeDescription = inheritedType.type.description
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if typeDescription == protocolName
                || typeDescription == qualifiedName
            {
                return true
            }
        }
        return false
    }
}

///  - ``ActorDeclSyntax``.``ActorDeclSyntax/inheritanceClause``
///  - ``AssociatedTypeDeclSyntax``.``AssociatedTypeDeclSyntax/inheritanceClause``
///  - ``ClassDeclSyntax``.``ClassDeclSyntax/inheritanceClause``
///  - ``EnumDeclSyntax``.``EnumDeclSyntax/inheritanceClause``
///  - ``ExtensionDeclSyntax``.``ExtensionDeclSyntax/inheritanceClause``
///  - ``ProtocolDeclSyntax``.``ProtocolDeclSyntax/inheritanceClause``
///  - ``StructDeclSyntax``.``StructDeclSyntax/inheritanceClause``

extension ActorDeclSyntax: _Conformable {
    var _inheritanceClause: SwiftSyntax.InheritanceClauseSyntax? {
        inheritanceClause
    }
    var _typeName: String { name.text }
}

extension AssociatedTypeDeclSyntax: _Conformable {
    var _inheritanceClause: SwiftSyntax.InheritanceClauseSyntax? {
        inheritanceClause
    }
    var _typeName: String { name.text }
}

extension ClassDeclSyntax: _Conformable {
    var _inheritanceClause: SwiftSyntax.InheritanceClauseSyntax? {
        inheritanceClause
    }
    var _typeName: String { name.text }
}

extension EnumDeclSyntax: _Conformable {
    var _inheritanceClause: SwiftSyntax.InheritanceClauseSyntax? {
        inheritanceClause
    }
    var _typeName: String { name.text }
}

extension ExtensionDeclSyntax: _Conformable {
    var _inheritanceClause: SwiftSyntax.InheritanceClauseSyntax? {
        inheritanceClause
    }
    var _typeName: String {
        extendedType.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension ProtocolDeclSyntax: _Conformable {
    var _inheritanceClause: SwiftSyntax.InheritanceClauseSyntax? {
        inheritanceClause
    }
    var _typeName: String { name.text }
}

extension StructDeclSyntax: _Conformable {
    var _inheritanceClause: SwiftSyntax.InheritanceClauseSyntax? {
        inheritanceClause
    }
    var _typeName: String { name.text }
}
