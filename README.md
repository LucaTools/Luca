# Luca

[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS-blue.svg)](https://apple.com/macos)
[![License](https://img.shields.io/badge/License-Apache%202-green.svg)](LICENSE)

Luca is a lightweight tool manager for macOS that helps developers install, manage, and activate specific versions of development tools in their projects. It creates project-specific tool environments without polluting your global PATH.

## Features

- **Version-specific installations**: Install specific versions of tools needed for your project
- **Project isolation**: Each project can have its own set of active tools
- **Simple specification**: Define required tools in a simple YAML file (Lucafile)
- **Zero configuration**: Just create a Lucafile and run `luca install`
- **No PATH pollution**: Tools are symlinked locally in your project directory
- **Idempotent operations**: Safe to run multiple times

## Installation

### Stable version

Install the latest version with

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/LucaTools/LucaScripts/HEAD/install.sh)"
```

Optionally define per-project `.luca-version` files containing the desired version before running the above command

```bash
echo "1.0.0" > .luca-version
```

### From Source

```bash
git clone https://github.com/LucaTools/Luca.git
cd Luca
swift build -c release
cp -f .build/release/luca /usr/local/bin/luca
```

## Usage

### Installing tools using a Lucafile

1. Create a `Lucafile` in your project directory:

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
```

2. Install the tools:

```bash
luca install
```

### Installing tools directly from GitHub

You can also install tools directly from GitHub releases by specifying the organization, repository, and version:

```bash
luca install TogglesPlatform/ToggleGen@1.0.0
```

Specify the name of the release asset if the naming is not clear enough for Luca to work it out:

```bash
luca install krzysztofzablocki/sourcery@2.2.7 --asset sourcery-2.2.7.zip
```

Symlinks will be created in the current directory at `.luca/active`.

3. Use your tools:

```bash
tuist --help
swiftlint --help
```

### Uninstalling tools

Uninstall a specific tool version:

```bash
luca uninstall SwiftLint
# Prompts to select a version to uninstall
```

Or specify the version directly:

```bash
luca uninstall SwiftLint@0.61.0
```

## How It Works

Luca performs the following steps:

1. Reads the tool specifications from your Lucafile
2. Downloads the specified zip files if they're not already installed
3. Extracts the binaries to `~/.luca/tools/{tool-name}/{version}/`
4. Creates symlinks in `.luca/active/` in your current directory
5. Tools can then be accessed via `.luca/active/{binary-name}`

## Lucafile Format

The Lucafile is a YAML file with the following structure:

```yaml
---
tools:
  - name: ToolName              # Logical name for the tool
    version: 1.2.3              # Version to install
    url: https://example.com/tool-1.2.3.zip  # Remote URL to an archive containing the tool or an executable file.
    binaryPath: path/to/binary  # Path to the binary within the archive file, if the release comes as an archive (optional)    
```

## Requirements

- macOS 13.0 or later
- Swift 5.7 or later (for building from source)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.
