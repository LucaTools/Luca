//  CommonFlags.swift

import ArgumentParser

/// Flags shared across all luca commands that participate in the auto-update flow.
struct CommonFlags: ParsableArguments {

    @Flag(help: ArgumentHelp(
        "Skip the automatic self-update check.",
        discussion: """
        By default, luca checks for a newer version before running any command. \
        Pass this flag to suppress that check, which is useful in CI \
        environments or when running luca offline.
        """
    ))
    var noAutoUpdate: Bool = false
}
