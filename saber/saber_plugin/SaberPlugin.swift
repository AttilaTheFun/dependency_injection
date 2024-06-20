import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SaberPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ArgumentMacro.self,
        FactoryMacro.self,
        InjectableMacro.self,
        InjectMacro.self,
        StoreMacro.self,
    ]
}