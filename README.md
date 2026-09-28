# ViewModelTestSuite Macro
A Swift macro that generates the members every view model test suite repeats: the `tester` that
drives the view model, and the parameterized test that runs the suite's `actionCases`.

## Overview

Annotate a `final class` suite with `@ViewModelTestSuite` and declare
`func makeViewModel() -> SomeViewModel`. The macro adds:

- `lazy var tester: ViewModelTester<SomeViewModel>`, created from `makeViewModel()` on first use.
  Because it is lazy, `makeViewModel()` can use the suite's other stored properties, such as mocks.
- If the suite declares `static let actionCases`, an extension with the parameterized test
  `actionUpdatesState(_:)`, which runs each `ActionCase` through the tester.

```swift
import Testing
import UnitTestSupport
import ViewModelTestSuite

@Suite("CropListViewModel", .serialized)
@ViewModelTestSuite
final class CropListViewModelTests {
  let mediaStore = MediaStoreMock()

  func makeViewModel() -> CropListViewModel {
    CropListViewModel(
      dependencies: .init(mediaStore: mediaStore),
      parameters: .init()
    )
  }

  static let actionCases: [ActionCase<CropListViewModel>] = [
    .init(
      "ShowAllDeficiencies triggers ShowAllDeficiencies",
      action: { CropListViewModel.Actions.ShowAllDeficiencies() },
      matches: { $0.kt.trigger is CropListState.TriggerShowAllDeficiencies }
    )
  ]

  @Test("Appearing loads crops")
  func appearingLoadsCrops() {
    tester.appear()

    #expect(tester.waitUntil { $0.kt.crops.success != nil })
  }
}
```

## Expansion

For the suite above, the macro produces:

```swift
final class CropListViewModelTests {
  // ...

  lazy var tester: ViewModelTester<CropListViewModel> = ViewModelTester(makeViewModel())
}

extension CropListViewModelTests {
  @Test("Actions update the state", arguments: actionCases)
  func actionUpdatesState(_ testCase: ActionCase<CropListViewModel>) {
    #expect(tester.run(testCase))
  }
}
```

The test is emitted in an extension, not as a member. Swift Testing's `@Test` only sees the
enclosing type of macro-generated code when that code is nested in a type declaration of the same
expansion. As a member, `@Test` would generate code for file scope, which does not compile.

## Requirements

- The suite is a class. A struct cannot initialize a `lazy var` from its non-mutating test methods.
- It declares `func makeViewModel()` without parameters and with an explicit return type.
- `actionCases`, if declared, is `static`, so it can be passed to `@Test(arguments:)`.
- The file imports the modules that declare `ViewModelTester`, `ActionCase` and `Testing`. The
  macro only generates code; it does not depend on them. In
  [kali-app-mobile](https://github.com/num42/kali-app-mobile), `ViewModelTester` and `ActionCase`
  are in the `UnitTestSupport` module.

The macro reports an error for each unmet requirement.

## Testing

```bash
swift test --enable-experimental-prebuilts
```

The test target enables `InternalImportsByDefault`. SwiftPM's generated test entry point uses a
plain `import Testing`, which since Swift 6.4 clashes with the `internal import Testing` in the
test files otherwise.
