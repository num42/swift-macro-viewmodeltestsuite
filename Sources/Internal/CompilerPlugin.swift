internal import SwiftCompilerPlugin
internal import SwiftSyntaxMacros

@main
struct ViewModelTestSuitePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    ViewModelTestSuiteMacro.self
  ]
}
