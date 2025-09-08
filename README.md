# Luca

[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS-blue.svg)](https://apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Luca is a lightweight tool manager for macOS that helps developers install, manage, and activate specific versions of development tools in their projects. It creates project-specific tool environments without polluting your global PATH.

## Features

- **Version-specific installations**: Install specific versions of tools needed for your project
- **Project isolation**: Each project can have its own set of active tools
- **Simple specification**: Define required tools in a simple YAML file (Lucafile)
- **Zero configuration**: Just create a Lucafile and run `luca install`
- **No PATH pollution**: Tools are symlinked locally in your project directory
- **Idempotent operations**: Safe to run multiple times

## Installation

### Latest version

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/LucaTools/Lucainstall/HEAD/install.sh)"
```

### From Source

```bash
git clone https://github.com/LucaTools/Luca.git
cd Luca
swift build -c release
cp -f .build/release/luca /usr/local/bin/luca
```

## Quick Start

1. Create a `Lucafile` in your project directory:

```yaml
---
tools:
  - name: PackageGenerator
    binaryPath: PackageGenerator
    version: 3.3.0
    zipUrl: https://github.com/justeattakeaway/PackageGenerator/releases/download/3.3.0/PackageGenerator-macOS.zip
  - name: Sourcery
    binaryPath: bin/sourcery
    version: 2.2.5
    zipUrl: https://github.com/krzysztofzablocki/Sourcery/releases/download/2.2.5/sourcery-2.2.5.zip
version: 0.0.1
```

2. Install the tools:

```bash
luca install
```

3. Use your tools:

```bash
PackageGenerator --help
sourcery --help
```

## Usage

### Install tools

Installs all tools defined in the Lucafile in the current directory:

```bash
luca install
```

Specify a custom Lucafile location:

```bash
luca install --spec /path/to/custom/Lucafile
```

### Clean installed tools

Remove all installed tools and symlinks:

```bash
luca clean
```

## How It Works

Luca performs the following steps:

1. Reads the tool specifications from your Lucafile
2. Downloads the specified zip files if they're not already installed
3. Extracts the binaries to `~/.luca/tools/{tool-name}/{version}/`
4. Creates symlinks in `.luca/active/` in your current directory
5. Tools can then be accessed via `.luca/active/{binary-name}`

You can add `.luca/active` to your project-specific PATH or invoke the tools directly.

## Lucafile Format

The Lucafile is a YAML file with the following structure:

```yaml
---
tools:
  - name: ToolName              # Logical name for the tool
    binaryPath: path/to/binary  # Path to the binary within the zip file
    version: 1.2.3              # Version to install
    zipUrl: https://example.com/tool-1.2.3.zip  # URL to download the zip archive
version: 0.0.1                  # Lucafile schema version
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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
