enum MacroError: Error, CustomStringConvertible {
    case notYetImplemented
    case invalidDeclaration
    case noContainerFound
    case cannotDetermineType
    case missingInitialValue
    case invalidInitialValue
    case duplicateKeyName(String)
    case invalidPrefix(String)

    case invalidEnclosingContainerDecl(String)
    case invalidEnclosingContainer(String)
    case invalidContainerType

    var description: String {
        switch self {
        case .notYetImplemented:
            return "This feature is not yet implemented."
        case .invalidDeclaration:
            return "@Setting can only be applied to variable declarations"
        case .noContainerFound:
            return "@Setting must be declared within a type conforming to __Settings_Container"
        case .cannotDetermineType:
            return "Cannot determine the type of the property. Please provide a type annotation."
        case .missingInitialValue:
            return "Non-optional @Setting properties require an initial value"
        case .invalidInitialValue:
            return "Optional @Setting properties should not have an initial value"
        case .duplicateKeyName(let keyName):
            return "Duplicate name name '\(keyName)' detected. Each name name should be unique within a store."
        case .invalidPrefix(let message):
            return message

        case .invalidEnclosingContainerDecl(let decl):
            return "A @Setting declaration cannot reside inside a \(decl) declaration."

        case .invalidEnclosingContainer(let what):
            return "A @Setting declaration cannot reside inside a \(what)."
        case .invalidContainerType:
            return "@Settings can only be applied to struct, class, enum, or actor declarations"
        }
    }
}
