internal import SwiftSyntaxMacrosGenericTestSupport
internal import Testing

#if canImport(ViewModelTestSuiteMacros)
  import ViewModelTestSuiteMacros

  @Suite
  struct ViewModelTestSuiteDiagnosticsTests {
    @Test func structThrowsError() {
      assertMacroExpansion(
        """
        @ViewModelTestSuite
        struct NotAClass {
          func makeViewModel() -> SomeViewModel { SomeViewModel() }
        }
        """,
        expandedSource: """
          struct NotAClass {
            func makeViewModel() -> SomeViewModel { SomeViewModel() }
          }
          """,
        diagnostics: [
          .init(
            message: ViewModelTestSuiteMacro.MacroDiagnostic.requiresClass.message,
            line: 1,
            column: 1
          )
        ],
        macros: testMacros
      )
    }

    @Test func missingMakeViewModelThrowsError() {
      assertMacroExpansion(
        """
        @ViewModelTestSuite
        final class MissingMakeViewModel {
          func makeTester() -> SomeViewModel { SomeViewModel() }
        }
        """,
        expandedSource: """
          final class MissingMakeViewModel {
            func makeTester() -> SomeViewModel { SomeViewModel() }
          }
          """,
        diagnostics: [
          .init(
            message: ViewModelTestSuiteMacro.MacroDiagnostic.requiresMakeViewModel.message,
            line: 1,
            column: 1
          )
        ],
        macros: testMacros
      )
    }

    @Test func makeViewModelWithoutReturnTypeThrowsError() {
      assertMacroExpansion(
        """
        @ViewModelTestSuite
        final class MissingReturnType {
          func makeViewModel() {}
        }
        """,
        expandedSource: """
          final class MissingReturnType {
            func makeViewModel() {}
          }
          """,
        diagnostics: [
          .init(
            message: ViewModelTestSuiteMacro.MacroDiagnostic.requiresMakeViewModel.message,
            line: 1,
            column: 1
          )
        ],
        macros: testMacros
      )
    }

    @Test func instanceActionCasesThrowsError() {
      assertMacroExpansion(
        """
        @ViewModelTestSuite
        final class InstanceActionCases {
          let actionCases: [ActionCase<SomeViewModel>] = []

          func makeViewModel() -> SomeViewModel { SomeViewModel() }
        }
        """,
        expandedSource: """
          final class InstanceActionCases {
            let actionCases: [ActionCase<SomeViewModel>] = []

            func makeViewModel() -> SomeViewModel { SomeViewModel() }
          }
          """,
        diagnostics: [
          .init(
            message: ViewModelTestSuiteMacro.MacroDiagnostic.requiresStaticActionCases.message,
            line: 1,
            column: 1
          )
        ],
        macros: testMacros
      )
    }
  }
#endif
