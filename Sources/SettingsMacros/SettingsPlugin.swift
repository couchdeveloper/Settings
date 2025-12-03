import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct SettingsPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SettingMacro.self,
        SettingsMacro.self,
    ]
}
