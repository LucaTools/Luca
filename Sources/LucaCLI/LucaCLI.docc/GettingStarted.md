# Getting Started with Luca

Learn how to install Luca and set up your first project with managed tools and agentic skills.

## Overview

Luca is a lightweight tool and skill manager for macOS and Linux that helps developers install, manage, and activate specific versions of development tools and AI coding agent skills in their projects. It creates project-specific environments without polluting your global PATH.

## Installation

### Using the Install Script (Recommended)

Install the latest stable version with a single command:

```bash
curl -fsSL https://luca.tools/install.sh | bash
```

#### Pinning a Specific Version

To pin a specific version of Luca for your project, create a `.luca-version` file before running the install script:

```bash
echo "0.15.0" > .luca-version
```

### Building from Source

If you prefer to build from source:

```bash
git clone https://github.com/LucaTools/Luca.git
cd Luca
swift build -c release
cp -f .build/release/luca /usr/local/bin/luca
```

## Requirements

- macOS 13.0 or later
- Swift 5.7 or later (for building from source)

## Quick Start

### 1. Create a Lucafile

Create a `Lucafile` in your project's root directory:

```yaml
---
tools:
  - name: SwiftLint
    binaryPath: SwiftLintBinary.artifactbundle/swiftlint-0.61.0-macos/bin/swiftlint
    version: 0.61.0
    url: https://github.com/realm/SwiftLint/releases/download/0.61.0/SwiftLintBinary.artifactbundle.zip
```

### 2. Install Tools

Run Luca to download and install the tools:

```bash
luca install
```

### 3. Use Your Tools

Tools are symlinked to `.luca/tools/` in your project directory:

```bash
.luca/tools/swiftlint --version
```

## Installing from GitHub Directly

You can also install tools directly from GitHub releases without a Lucafile:

```bash
luca install TogglesPlatform/ToggleGen@1.0.0
```

If the release asset naming is ambiguous, specify the asset name:

```bash
luca install krzysztofzablocki/sourcery@2.2.7 --asset sourcery-2.2.7.zip
```

## Next Steps

- Learn about the <doc:Lucafile> configuration format
- Follow the <doc:Luca> tutorial for a hands-on introduction
