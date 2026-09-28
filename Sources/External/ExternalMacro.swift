/// Generates the members every view model test suite repeats.
///
/// Attach it to a `final class` suite that declares `func makeViewModel() -> SomeViewModel`. The
/// macro adds:
///
/// - `lazy var tester: ViewModelTester<SomeViewModel>`, created from `makeViewModel()` on first use.
///   Being lazy, `makeViewModel()` can use the suite's other stored properties, e.g. mocks.
/// - If the suite declares `actionCases`, the parameterized test
///   `actionUpdatesState(_:)`, which runs each `ActionCase` through the tester.
///
/// The generated code uses `ViewModelTester`, `ActionCase`, `@Test` and `#expect`, so the file must
/// import the modules that declare them.
@attached(member, names: named(tester))
@attached(extension, names: named(actionUpdatesState))
public macro ViewModelTestSuite() =
  #externalMacro(
    module: "ViewModelTestSuiteMacros",
    type: "ViewModelTestSuiteMacro"
  )
