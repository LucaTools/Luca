# Luca

[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20Linux-blue.svg)](https://swift.org/platform-support)
[![License](https://img.shields.io/badge/License-Apache%202-green.svg)](LICENSE)
[![codecov](https://codecov.io/github/LucaTools/Luca/graph/badge.svg)](https://app.codecov.io/github/LucaTools/Luca)

Luca is a lightweight tool manager for macOS and Linux that helps developers install, manage, and activate specific versions of development tools in their projects. It creates project-specific tool environments without polluting your global PATH.

## Features

- **Version-specific installations**: Install specific versions of tools needed for your project
- **Project isolation**: Each project can have its own set of active tools
- **Simple specification**: Define required tools in a simple YAML file (Lucafile)
- **Zero configuration**: Just create a Lucafile and run `luca install`
- **No PATH pollution**: Tools are symlinked locally in your project directory
- **Idempotent operations**: Safe to run multiple times
- **Skill management**: Install and manage agentic skills for AI coding agents (Claude Code, Cursor, GitHub Copilot, and more)

## Installation

### Stable version

Install the latest version with

```bash
curl -fsSL https://luca.tools/install.sh | bash
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

On Linux, you can build a portable binary that doesn't require the Swift runtime:

```bash
swift build -c release -Xswiftc -static-stdlib
```

## GitHub Actions

Two companion repositories make it easy to use Luca in CI:

- **[setup-luca](https://github.com/LucaTools/setup-luca)** — a GitHub Action (also on the [Marketplace](https://github.com/marketplace/actions/setup-luca)) that installs Luca and optionally install tools as part of your workflow.
- **[LucaWorkflows](https://github.com/LucaTools/LucaWorkflows)** — ready-to-use workflow templates to build, package, and publish Luca-compatible releases from Swift, Go, Rust, Python, C#, and Zig projects.

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

Symlinks will be created in the current directory at `.luca/tools`.

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

### Listing installed tools

List all tools and versions installed:

```bash
luca installed

FirebaseCLI:
  - 14.12.1
Sourcery:
  - 2.2.5
SwiftLint:
  - 0.53.0
  - 0.62.0
tuist:
  - 4.78.0
```

### Listing linked tools

List the tools linked in a project:

```bash
luca linked

FirebaseCLI:
  version: 14.12.1
  binary: firebasee
  location: /Users/alberto/.luca/tools/FirebaseCLI/14.12.1/firebasee
Sourcery:
  version: 2.2.5
  binary: sourcery
  location: /Users/alberto/.luca/tools/Sourcery/2.2.5/bin/sourcery
tuist:
  version: 4.78.0
  binary: tuist
  location: /Users/alberto/.luca/tools/tuist/4.78.0/tuist
```

### Unlinking tools

Remove a symlink from the current project's `.luca/tools` directory:

```bash
luca unlink swiftlint
```

### Installing skills using a Lucafile

Skills are agentic plugins for AI coding agents (Claude Code, Cursor, GitHub Copilot, and others). Add a `skills:` section to your Lucafile:

```yaml
---
skills:
  - name: swift-testing-expert         # Install a specific skill by name
    repository: vercel-labs/agent-skills
  - name: find-skills
    repository: vercel-labs/agent-skills
  - repository: https://github.com/AvdLee/Swift-Testing-Agent-Skill  # Omit 'name' to install all skills from a repository

agents:                                # Optional — omit to target all supported agents
  - claude-code
  - cursor
```

Then run:

```bash
luca install
```

Skills are installed into agent-specific directories (e.g. `.claude/skills/`, `.cursor/skills/`) in the current project.

### Installing skills directly from a repository

Install skills directly from a repository without a Lucafile:

```bash
# Install all skills from a repository
luca install vercel-labs/agent-skills

# Install specific skills by name
luca install vercel-labs/agent-skills --skill find-skills --skill swift-testing-expert

# Target specific agents only
luca install vercel-labs/agent-skills --agent claude-code --agent cursor
```

If you prefer to use [Vercel Labs' skills tool](https://github.com/vercel-labs/skills) instead of Luca's native pipeline, pass `--use-npx` (requires Node.js and npx):

```bash
luca install vercel-labs/agent-skills --use-npx
```

### Listing installed skills

```bash
luca installed --skills

find-skills
swift-testing-expert
```

### Uninstalling skills

```bash
luca uninstall find-skills
```

### Combining tools and skills

A Lucafile can define both `tools:` and `skills:` together. By default, `luca install` installs everything. Use `--only-tools` or `--only-skills` to install only one category:

```bash
luca install --only-tools   # Install binary tools, skip skills
luca install --only-skills  # Install skills, skip binary tools
```

## How It Works

Luca performs the following steps:

1. Reads the tool specifications from your Lucafile
2. Downloads the specified zip files if they're not already installed
3. Extracts the binaries to `~/.luca/tools/{tool-name}/{version}/`
4. Creates symlinks in `.luca/tools/` in your current directory
5. Tools can then be accessed via `.luca/tools/{binary-name}`

## Lucafile Format

The Lucafile is a YAML file with the following structure:

```yaml
---
tools:
  - name: ToolName                           # Logical name for the tool
    version: 1.2.3                           # Version to install
    url: https://example.com/tool-1.2.3.zip  # Remote URL to an archive containing the tool or an executable file.
    binaryPath: path/to/binary               # Path to the binary within the archive file, if the release comes as an archive (optional)
    desiredBinaryName: toolname              # Name of the binary stored locally. Requires `url` to point to an executable file, ignored otherwise. (optional)
    checksum: e0a6540d01434f436335a9...      # The checksum hash of asset associated with the tool (optional)
    algorithm: (md5|sha1|sha256|sha512)      # The algorithm used to generate the checksum (optional)

skills:
  - name: skill-name                         # Name of the specific skill to install (optional — omit to install all skills from the repository)
    repository: owner/repo                   # GitHub shorthand (owner/repo) or full HTTPS/Git URL

agents:                                      # Agent identifiers to install skills for (optional — omit to target all supported agents)
  - claude-code
  - cursor
  - github-copilot
```

## Uninstallation

Completely uninstall the tool from the system:

```bash
curl -fsSL https://luca.tools/uninstall.sh | bash
```

## Requirements

- macOS 13.0 or later, or Linux (x86_64, arm64)
- Swift 5.7 or later (for building from source)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Find me on [X](https://x.com/albertodebo) / [Bluesky](https://bsky.app/profile/albertodebo.bsky.social) / [LinkedIn](https://www.linkedin.com/in/albertodebortoli/)


## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.
