# Lucafile Configuration

Learn how to configure your project's tool dependencies using a Lucafile.

## Overview

A Lucafile is a YAML configuration file that defines the tools your project needs. Luca reads this file to download, install, and manage tool versions specific to your project.

## File Location

Place your `Lucafile` (or `Lucafile.yml`) in your project's root directory.

## Basic Structure

```yaml
---
tools:
  - name: ToolName
    version: 1.2.3
    url: https://example.com/tool-1.2.3.zip
```

## Configuration Fields

### Required Fields

| Field | Description |
|-------|-------------|
| `name` | Logical name for the tool (used for organizing and referencing) |
| `version` | The version to install |
| `url` | Remote URL to the archive or executable file |

### Optional Fields

| Field | Description |
|-------|-------------|
| `binaryPath` | Path to the binary within an archive (required for archives with nested structure) |
| `desiredBinaryName` | Custom name for the binary when stored locally |
| `checksum` | Hash value for verifying the downloaded file |
| `algorithm` | Hash algorithm used: `md5`, `sha1`, `sha256`, or `sha512` |

## Examples

### Simple Executable

For tools distributed as standalone executables:

```yaml
tools:
  - name: FirebaseCLI
    version: 14.12.1
    url: https://github.com/firebase/firebase-tools/releases/download/v14.12.1/firebase-tools-macos
```

### Archive with Binary Path

For tools distributed in archives with nested directory structures:

```yaml
tools:
  - name: SwiftLint
    binaryPath: SwiftLintBinary.artifactbundle/swiftlint-0.61.0-macos/bin/swiftlint
    version: 0.61.0
    url: https://github.com/realm/SwiftLint/releases/download/0.61.0/SwiftLintBinary.artifactbundle.zip
```

### Simple Archive

For tools where the binary is at the root of the archive:

```yaml
tools:
  - name: Tuist
    binaryPath: tuist
    version: 4.80.0
    url: https://github.com/tuist/tuist/releases/download/4.80.0/tuist.zip
```

### With Checksum Verification

For enhanced security, verify downloads with checksums:

```yaml
tools:
  - name: SwiftLint
    binaryPath: SwiftLintBinary.artifactbundle/swiftlint-0.61.0-macos/bin/swiftlint
    version: 0.61.0
    url: https://github.com/realm/SwiftLint/releases/download/0.61.0/SwiftLintBinary.artifactbundle.zip
    checksum: e0a6540d01434f436335a9b12c7fabc3a6f5c3e8...
    algorithm: sha256
```

### Complete Example

A typical Lucafile with multiple tools:

```yaml
---
tools:
  - name: FirebaseCLI
    version: 14.12.1
    url: https://github.com/firebase/firebase-tools/releases/download/v14.12.1/firebase-tools-macos

  - name: SwiftLint
    binaryPath: SwiftLintBinary.artifactbundle/swiftlint-0.61.0-macos/bin/swiftlint
    version: 0.61.0
    url: https://github.com/realm/SwiftLint/releases/download/0.61.0/SwiftLintBinary.artifactbundle.zip

  - name: Tuist
    binaryPath: tuist
    version: 4.80.0
    url: https://github.com/tuist/tuist/releases/download/4.80.0/tuist.zip

  - name: Sourcery
    binaryPath: bin/sourcery
    version: 2.2.7
    url: https://github.com/krzysztofzablocki/Sourcery/releases/download/2.2.7/sourcery-2.2.7.zip
    checksum: abc123...
    algorithm: sha256
```

## How Tools Are Stored

When you run `luca install`, Luca:

1. Downloads the specified files
2. Verifies checksums (if provided)
3. Extracts archives (if applicable)
4. Stores binaries in `~/.luca/tools/{name}/{version}/`
5. Creates symlinks in `.luca/tools/` in your project

## Best Practices

### Version Pinning

Always specify exact versions to ensure reproducible builds across your team.

### Checksum Verification

Use checksums for critical tools to verify integrity and protect against tampering.

### Git Integration

Add `.luca/tools/` to your `.gitignore` file. Luca can manage this automatically with the `--install-git-hook` flag.

## Related

- <doc:GettingStarted>
- ``Spec``
- ``SpecLoader``
