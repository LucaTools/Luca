//  InstallCommandTests.swift

import Foundation
import Testing

// NOTE: InstallCommand lives in the LucaCLI *executable* target, which cannot be imported
// by the LucaTests test target (Swift does not allow test targets to depend on executable
// targets). The two command-layer tests below are therefore stubbed with a clear TODO.
//
// To unblock these tests one of the following approaches would be needed:
//   A) Extract the validation/resolution logic into a new library target (e.g. LucaCLICore)
//      that both LucaCLI and LucaTests can depend on.
//   B) Add a dedicated test-only executable target that re-exports LucaCLI.
//   C) Move the `--global && --only-tools` guard into LucaCore (e.g. as a standalone
//      validator) so it can be tested without the CLI layer.

struct InstallCommandTests {

    // MARK: - Fix 2: --global --only-tools should be rejected

    // TODO: Add LucaCLI as a testable dependency (see note above) then replace this
    // placeholder with:
    //
    //   @Test
    //   func test_globalAndOnlyTools_throwsValidationError() throws {
    //       #expect(throws: (any Error).self) {
    //           try InstallCommand.parse(["--global", "--only-tools"])
    //       }
    //       // Optionally assert the thrown error is a ValidationError with the expected message.
    //   }
    //
    // The guard in InstallCommand.run() throws:
    //   ValidationError("--global cannot be combined with --only-tools. Global installation is skills-only.")

    // MARK: - Fix 3: --global defaults spec to ~/.config/luca/Lucafile

    // TODO: Add LucaCLI as a testable dependency (see note above) then replace this
    // placeholder with:
    //
    //   @Test
    //   func test_globalFlag_resolvesToGlobalLucafile() throws {
    //       // Parse the command with --global only (no --spec).
    //       var cmd = try InstallCommand.parse(["--global"])
    //       // The resolution to ~/.config/luca/Lucafile happens inside run(), so we
    //       // cannot assert it without running the command. Instead, verify that the
    //       // parsed `spec` property is nil (meaning the default resolution will kick in)
    //       // and `global` is true.
    //       #expect(cmd.global == true)
    //       #expect(cmd.spec == nil)
    //       // The actual resolved path (~/.config/luca/Lucafile) is computed in run().
    //       // To fully test the resolution, refactor specPath logic into LucaCore or a
    //       // testable helper.
    //   }
}
