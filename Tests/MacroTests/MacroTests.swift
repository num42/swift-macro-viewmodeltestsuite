internal import MacroTester
internal import SwiftSyntaxMacros
internal import Testing

#if canImport(ViewModelTestSuiteMacros)
  import ViewModelTestSuiteMacros

  let testMacros: [String: Macro.Type] = [
    "ViewModelTestSuite": ViewModelTestSuiteMacro.self
  ]

  @Suite
  struct ViewModelTestSuiteMacroTests {
    @Test func suiteWithActionCases() {
      MacroTester.testMacro(macros: testMacros)
    }

    @Test func suiteWithoutActionCases() {
      MacroTester.testMacro(macros: testMacros)
    }
  }
#endif
