---
module: Leaf
date: 2026-03-28
problem_type: test_failure
category: docs/solutions/test-failures/
component: testing_framework
symptoms: "xcodebuild test failed for the macOS app after introducing shared testable logic, including an ___llvm_profile_runtime linker error and follow-on test/product expectation mismatches."
root_cause: config_error
resolution_type: config_change
severity: medium
---

# macOS test setup broke after extracting shared testable logic

## Problem

Leaf needed a stable way to run both unit tests and UI tests from the main scheme with:

```sh
xcodebuild test -project Leaf/Leaf.xcodeproj -scheme Leaf -destination 'platform=macOS'
```

`LeafUITests` already worked because they launch the app externally. `LeafTests` were the weak point because too much non-UI logic only lived in the app target, and the hosted-unit-test setup was fragile.

## Symptoms

- `LeafUITests` passed, but `LeafTests` were brittle and tightly coupled to app-target structure.
- Core logic like document loading, parsing, rendering, and reader state could not be exercised cleanly as ordinary unit tests.
- `xcodebuild test` failed once the setup depended on a separate framework target.
- Two behavior bugs surfaced while tightening tests:
  - inline code rendered with literal backticks
  - security-scoped file release bypassed the file-service seam

## What Didn't Work

The first attempt created a separate `LeafCore` framework target so both the app and tests could import shared code. That looked clean architecturally, but the coverage-enabled test path became unstable.

Concrete failure:

```text
Undefined symbol: ___llvm_profile_runtime
```

That made the extra-framework approach too fragile for the repo's real verification command.

## Solution

Move non-UI logic into a shared source folder:

```text
Leaf/LeafCore/
```

Then compile those same files into both the `Leaf` target and the `LeafTests` target instead of introducing a new linked framework product.

Shared files:

- `Leaf/LeafCore/DocumentStore.swift`
- `Leaf/LeafCore/FileService.swift`
- `Leaf/LeafCore/LeafTheme.swift`
- `Leaf/LeafCore/MarkdownParser.swift`
- `Leaf/LeafCore/MarkdownRenderModel.swift`
- `Leaf/LeafCore/ReaderInteractionState.swift`
- `Leaf/LeafCore/RenderService.swift`
- `Leaf/LeafCore/SidebarViewModel.swift`

Two concrete code fixes landed while hardening tests:

1. Inline code rendering now uses `inlineCode.code` instead of `inlineCode.plainText`, which removes stray backticks from rendered output.
2. `DocumentStore` now releases security-scoped access through `fileService.stopAccessing(document.url)` instead of bypassing the file-service seam.

UI tests stayed app-realistic:

- launch the real app externally
- target stable accessibility identifiers
- load fixture content through launch arguments and environment

## Why This Works

This avoids the unstable part of the earlier design: a separately linked framework target in coverage-enabled macOS test runs.

Compiling the same `LeafCore` files directly into both targets gives Leaf:

- a stable unit-test boundary for non-UI logic
- no extra framework product to link
- unit tests that do not depend on unhealthy hosted-test bootstrapping
- app code and test code exercising the same production implementation

## Prevention

- Prefer shared-source inclusion over a new framework target when the goal is only to make app-owned logic testable inside the same Xcode project.
- Verify test-infrastructure changes with the full command, not just target-local builds:
  ```sh
  xcodebuild test -project Leaf/Leaf.xcodeproj -scheme Leaf -destination 'platform=macOS'
  ```
- Keep non-UI logic in `Leaf/LeafCore/` and keep SwiftUI-only code in the app target.
- Preserve abstraction seams in test-sensitive paths, especially file access and cleanup.
- Add regression tests for renderer details that are easy to miss visually, especially inline code and URL normalization.

## Related Issues

- [QUALITY_SCORE.md](/Users/kn_neeraj/Documents/ai-projects/leaf_project/docs/QUALITY_SCORE.md)
- [implementation_spec_sidebar_multifile.md](/Users/kn_neeraj/Documents/ai-projects/leaf_project/docs/design-docs/architecture-notes/implementation_spec_sidebar_multifile.md)
- [implementation_plan_v1.md](/Users/kn_neeraj/Documents/ai-projects/leaf_project/docs/design-docs/architecture-notes/implementation_plan_v1.md)
- [v1_task_checklist.md](/Users/kn_neeraj/Documents/ai-projects/leaf_project/docs/design-docs/architecture-notes/v1_task_checklist.md)
