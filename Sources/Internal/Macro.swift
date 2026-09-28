public import SwiftDiagnostics
public import SwiftSyntax
public import SwiftSyntaxMacros

public struct ViewModelTestSuiteMacro: MemberMacro, ExtensionMacro {
  public enum MacroDiagnostic: String, DiagnosticMessage {
    case requiresClass = "@ViewModelTestSuite requires a class"
    case requiresMakeViewModel =
      "@ViewModelTestSuite requires a func makeViewModel() without parameters and with an explicit return type"
    case requiresStaticActionCases =
      "@ViewModelTestSuite requires actionCases to be static, so it can be passed to @Test(arguments:)"

    public var message: String { rawValue }

    public var diagnosticID: MessageID {
      MessageID(domain: "ViewModelTestSuite", id: rawValue)
    }

    public var severity: DiagnosticSeverity { .error }
  }

  public static func expansion(
    of attribute: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    /*
     Expansion algorithm (high level):

     1. Require a class. The generated `tester` is a `lazy var`, and lazy properties cannot be
        initialized from the non-mutating test methods of a struct.
     2. Find `func makeViewModel() -> SomeViewModel` and read its return type.
     3. Emit `lazy var tester: ViewModelTester<SomeViewModel>`, created from `makeViewModel()` on
        first use. Being lazy, `makeViewModel()` can read the suite's other stored properties.
     4. If the class declares `actionCases`, require it to be static and emit, in an extension, the
        parameterized `actionUpdatesState(_:)` test, which runs each `ActionCase` through the tester.
    */

    let suite = try Suite(declaration, attribute: attribute)

    return [
      """
      lazy var tester: ViewModelTester<\(raw: suite.viewModelType)> = ViewModelTester(makeViewModel())
      """
    ]
  }

  public static func expansion(
    of attribute: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    // The member expansion reports invalid suites. Reporting them here too would duplicate them.
    guard let suite = try? Suite(declaration, attribute: attribute), suite.hasActionCases else {
      return []
    }

    // In an extension rather than as a member: `@Test` only sees the enclosing type of code that a
    // macro generates if that code is nested in a type declaration of the same expansion.
    let actionTest: DeclSyntax = """
      extension \(type.trimmed) {
        @Test("Actions update the state", arguments: actionCases)
        func actionUpdatesState(_ testCase: ActionCase<\(raw: suite.viewModelType)>) {
          #expect(tester.run(testCase))
        }
      }
      """

    return [actionTest.cast(ExtensionDeclSyntax.self)]
  }

  /// What the macro needs to know about the suite it is attached to.
  private struct Suite {
    let viewModelType: String
    let hasActionCases: Bool

    init(_ declaration: some DeclGroupSyntax, attribute: AttributeSyntax) throws {
      guard let classDeclaration = declaration.as(ClassDeclSyntax.self) else {
        throw ViewModelTestSuiteMacro.diagnose(.requiresClass, at: attribute)
      }

      let members = classDeclaration.memberBlock.members

      guard
        let makeViewModel =
          members
          .compactMap({ $0.decl.as(FunctionDeclSyntax.self) })
          .first(where: {
            $0.name.text == "makeViewModel" && $0.signature.parameterClause.parameters.isEmpty
          }),
        let viewModelType = makeViewModel.signature.returnClause?.type.trimmedDescription
      else {
        throw ViewModelTestSuiteMacro.diagnose(.requiresMakeViewModel, at: attribute)
      }

      let actionCases =
        members
        .compactMap { $0.decl.as(VariableDeclSyntax.self) }
        .first { variable in
          variable.bindings.contains {
            $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "actionCases"
          }
        }

      if let actionCases,
        !actionCases.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
      {
        throw ViewModelTestSuiteMacro.diagnose(.requiresStaticActionCases, at: attribute)
      }

      self.viewModelType = viewModelType
      hasActionCases = actionCases != nil
    }
  }

  fileprivate static func diagnose(
    _ message: MacroDiagnostic,
    at attribute: AttributeSyntax
  ) -> DiagnosticsError {
    // Only thrown, not also passed to `context.diagnose`, which would report it twice.
    DiagnosticsError(diagnostics: [Diagnostic(node: Syntax(attribute), message: message)])
  }
}
