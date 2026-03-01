# Agent Instructions

## Overview

Luca is a macOS & Linux CLI tool manager. It reads a YAML `Lucafile`, downloads versioned dev tools from remote URLs (GitHub Releases or direct links), validates checksums and binary architecture, and symlinks active tools into `.luca/active/` inside the project directory. Tools are cached at `~/.luca/tools/{ToolName}/{version}/`.

Two targets: `LucaCore` (library, all business logic) and `LucaCLI` (executable, thin command layer).

## Build & Test

```bash
swift build                  # debug
swift build -c release       # release (single arch)
swift test
swift package clean
```

Xcode version is pinned in [.xcode-version](.xcode-version). CI builds a universal binary (arm64 + x86_64) for macOS and a static binary for Linux x86_64.

### Linux (Docker)

```bash
docker run --rm -v "$PWD:/workspace" -w /workspace swift:6.0-jammy swift build --scratch-path /tmp/.build
docker run --rm -v "$PWD:/workspace" -w /workspace swift:6.0-jammy swift test --scratch-path /tmp/.build
```

CI runs tests on both macOS and Linux (`swift:6.0-jammy` container).

### Linux Gotchas

- **`FoundationNetworking`**: on Linux, `URLRequest`, `URLResponse`, and `URLSession.data(for:)` live in `FoundationNetworking`, not `Foundation`. Any file using these types needs:
  ```swift
  #if canImport(FoundationNetworking)
  import FoundationNetworking
  #endif
  ```
  This applies to source files *and* test mocks.
- **Warnings are errors**: Linux Swift treats some warnings (e.g. unused `@discardableResult` returns) as fatal. Always use `_ =` or `#expect(...)` for `FileManager.createFile(atPath:…)` calls in tests.
- **No `Bundle.module` unless resources exist**: `Bundle.module` is only synthesized when the target declares `resources:` in `Package.swift`. Test fixtures use this.

## Architecture

- **Protocol-oriented + DI**: every component depends on narrow protocols (e.g. `Downloading`, `BinaryFinding`, `ArchitectureValidating`). Implementations are `struct`s; mocks are in `Tests/Mocks/`.
- **Fine-grained FileManaging**: each component has its own `*FileManaging` protocol in `Sources/LucaCore/Core/FileManagerProtocols/`. `FileManagerWrapperMock` implements the full `FileManaging` protocol for tests.
- **`async throws` throughout**: all I/O-bound operations are async.
- **Nested error enums**: each component declares `*Error: Error, LocalizedError, Equatable` nested inside its struct.
- **Value types**: prefer `struct`. Use `class` only for mocks that accumulate state.

### Adding a Component

1. New subfolder under `Sources/LucaCore/Core/`
2. Define a `*ing` protocol + `struct` implementation + nested `*Error` enum
3. Add a `*FileManaging` protocol in `FileManagerProtocols/` if the component touches the file system
4. Add a mock in `Tests/Mocks/`
5. Add a test file in `Tests/Core/`

## Code Style

- Swift 6 (`swift-tools-version: 6.0`), strict concurrency
- File header: single-line `//  FileName.swift` — no copyright block
- DocC `///` comments on all public and internal types/methods
- `// MARK: -` dividers to separate protocol conformances and logical groups
- No force-unwraps in library code
- CLI `@Option`/`@Argument` always include `ArgumentHelp` with `discussion:` and `valueName:`

## Documentation

The `.docc` catalog (`Sources/LucaCore/LucaCore.docc/`) contains hand-written articles that must be committed. The generated HTML output (`docs/`) is produced by CI and must **not** be committed.

All new types, methods, protocols, and enums require `///` DocC comments. Follow this style:

- **Type-level**: one-sentence summary on the first `///` line; add a short paragraph if the role needs clarification.
- **Methods**: add `- Parameter x:` and `- Returns:` only when non-obvious.
- **`*FileManaging` protocols**: single-line doc only (e.g. `/// File system interface for ``BinaryFinder``.`).

See `Installer.swift`, `Tool.swift`, and `Spec.swift` as style exemplars.

## Testing

Uses **Swift Testing** (not XCTest).

- Test types are `struct`s with `init() async throws` for setup
- Naming: `test_<subject>_<condition>`
- Assertions: `#expect(...)` and `#require(...)` — never `XCTAssert`
- Parameterized tests via `@Test(arguments:)`
- File system interaction: use `FileManagerWrapperMock`, which redirects home/CWD to a UUID-named temp directory for full isolation
- Fixtures loaded from `Bundle.module` via the `Fixture(filename:type:)` helper

## Pull Request

- Always create a pull request for new features
- Always respect the template at .github/PULL_REQUEST_TEMPLATE.md
