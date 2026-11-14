# Known toolchain issues

Things that look fine locally but break in CI or release builds. Agents: read before writing app code.

## Linux x64 AOT crash: `linearscan.cc: unreachable code` (Flutter 3.50 / Dart 3.14)

- **Symptom:** `flutter build linux --release` (desktop-it's "Release build contains no DebugDrive" step) aborts with
  `vm/compiler/backend/linearscan.cc: 3013: error: unreachable code` / `AOT snapshotter exited with code -6`.
  Debug builds, tests and `dart compile exe` repros all pass.
- **Trigger found (#60):** a `switch` *statement* that assigns a `final` local declared before it (one case
  assigns, another `return`s), inside an `async` closure (`guardStorage(() async { … })`).
- **Avoid:** prefer a `switch` *expression*, or move the rest of the body into a separate method.
- **How to find the function if it happens again:** on a throwaway branch run
  `flutter build linux --release --extra-gen-snapshot-options=--trace_compiler` and look at the last
  `Precompiling optimized function:` line before the crash.
- Revisit when the Flutter pin is bumped; report upstream with a minimal repro if one can be built.
