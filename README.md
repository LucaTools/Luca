# Luca

[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20Linux-blue.svg)](https://swift.org/platform-support)
[![License](https://img.shields.io/badge/License-Apache%202-green.svg)](LICENSE)
[![codecov](https://codecov.io/github/LucaTools/Luca/graph/badge.svg)](https://app.codecov.io/github/LucaTools/Luca)

Luca is a lightweight and decentralised tool manager with support for agentic skills and building local pipelines. It supports both macOS and Linux. It helps developers install, manage, and activate specific versions of development tools in their projects, install agentic skills for AI coding agents (Claude Code, Cursor, GitHub Copilot, and more), and run ordered sequences of shell tasks via a built-in pipeline engine. It creates project-specific tool environments without polluting your global PATH.

## Features

- **Version-specific installations**: Install specific versions of tools needed for your project
- **Project isolation**: Each project can have its own set of active tools
- **Simple specification**: Define required tools in a simple YAML file (Lucafile)
- **Zero configuration**: Just create a Lucafile and run `luca install`
- **No PATH pollution**: Tools are symlinked locally in your project directory
- **Idempotent operations**: Safe to run multiple times
- **Skill management**: Install and manage agentic skills for AI coding agents (Claude Code, Cursor, GitHub Copilot, and more)
- **Pipeline runner**: Define and execute ordered sequences of shell tasks with parameters, conditions, and env-file support

## Installation

### Stable version

Install the latest version with

```bash
curl -fsSL https://luca.tools/install.sh | bash
```

Optionally define per-project `.luca-version` files containing the desired version before running the above command

```bash
echo "0.15.0" > .luca-version
```

### From Source

```bash
git clone https://github.com/LucaTools/Luca.git
cd Luca
swift build -c release
mkdir -p ~/.local/bin
cp -f .build/release/luca ~/.local/bin/luca
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

### Authenticating with private repositories & GitHub Enterprise Server

If a tool's `url` points at a private repository — on `github.com` or a GitHub Enterprise
Server instance — set an environment variable holding a personal access token before running
`luca install`:

- `github.com` reads `LUCA_GITHUB_TOKEN`.
- Any other host reads `LUCA_GITHUB_TOKEN_<HOST>`, where `<HOST>` is the hostname uppercased
  with every non-alphanumeric character replaced by `_`. For example, a Lucafile entry
  pointing at `https://ghe.my-company.com/iOS/ModuleCreator/releases/download/2.5.0/ModuleCreator-macOS.zip`
  is authenticated by setting `LUCA_GITHUB_TOKEN_GHE_MY_COMPANY_COM`.

```bash
export LUCA_GITHUB_TOKEN_GHE_MY_COMPANY_COM=ghp_xxxxxxxxxxxx
luca install
```

The token is only ever sent to the host it was configured for. Note that `github.com` asset
downloads never carry this header, even if `LUCA_GITHUB_TOKEN` is set — GitHub redirects those
downloads to a separate signed-URL storage host, so the token is unused there today; it is
still read and applied to the `api.github.com` release-metadata lookup used by
`luca install org/repo@version`.

#### GitHub Enterprise Server behind an SSO gateway (e.g. Okta)

If your GHE instance sits behind a browser-SSO gateway, the plain release-download URL
(`.../releases/download/{version}/{asset}`) may be intercepted before it reaches GHE and served
back as an HTML login page — even with `LUCA_GITHUB_TOKEN_<HOST>` set — because that URL is
treated as web traffic requiring an interactive session, not a token. The `/api/v3/...` paths are
typically exempt from that gate, since they're designed for token-based access. Point `url` at the
release's **API asset URL** instead of the browser download URL:

```bash
curl -H "Authorization: Bearer $LUCA_GITHUB_TOKEN_GHE_MY_COMPANY_COM" \
  https://ghe.my-company.com/api/v3/repos/iOS/ModuleCreator/releases/tags/2.5.0
```

Find the matching asset's `url` field in the response (not `browser_download_url`) — it looks like
`https://ghe.my-company.com/api/v3/repos/iOS/ModuleCreator/releases/assets/12345` — and use that in
your Lucafile:

```yaml
tools:
  - name: ModuleCreator
    version: 2.5.0
    url: https://ghe.my-company.com/api/v3/repos/iOS/ModuleCreator/releases/assets/12345
```

Luca always sends `Accept: application/octet-stream` on the download request, which the API asset
endpoint requires to return the raw binary instead of JSON metadata.

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
    repository: AvdLee/Swift-Testing-Agent-Skill
  - name: web-design-guidelines
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

Skills are installed into `.luca/skills/` in the current project and symlinked into agent-specific directories (e.g. `.claude/skills/`, `.cursor/skills/`).

### Installing skills directly from a repository

Install skills directly from a repository without a Lucafile:

```bash
# Install all skills from a repository
luca install vercel-labs/agent-skills

# Install specific skills by name
luca install vercel-labs/agent-skills --skill web-design-guidelines --skill deploy-to-vercel

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

web-design-guidelines
swift-testing-expert
```

### Uninstalling skills

```bash
luca uninstall swift-testing-expert
```

### Global skills

Some skills are useful across all projects and shouldn't require a per-project `Lucafile` to install. The `--global` flag installs skills to your home directory, making them available in any project.

**Install globally:**

```bash
# Install all skills from your global Lucafile (~/.config/luca/Lucafile)
luca install --global

# Install a specific skill globally from a repository
luca install org/repo --skill my-skill --global

# Use a custom global Lucafile instead of ~/.config/luca/Lucafile
luca install --global --spec ~/my-global-skills.yaml
```

**Uninstall a global skill:**

```bash
luca uninstall my-skill --global
```

**List globally installed skills:**

```bash
luca installed --skills --global
```

**Global paths:**

| Resource | Path |
|---|---|
| Global Lucafile | `~/.config/luca/Lucafile` |
| Global skill cache | `~/.luca/skills/` |
| Global agent dirs | Per agent (e.g. `~/.claude/skills/`, `~/.config/opencode/skills/`) — run `luca agents` for full list |

**Notes:**
- Running `luca install --global` again fetches the latest version of all skills (no separate update command needed)
- Project-local skills take precedence over global skills when both exist for the same agent
- `repos:` aliases in the global `Lucafile` are supported — the same spec parser is used
- `--global` is skills-only; tools already install globally to `~/.luca/tools/` and don't need this flag

### Combining tools and skills

A Lucafile can define both `tools:` and `skills:` together. By default, `luca install` installs everything. Use `--only-tools` or `--only-skills` to install only one category:

```bash
luca install --only-tools   # Install binary tools, skip skills
luca install --only-skills  # Install skills, skip binary tools
```

### Running pipelines

Pipelines let you define an ordered sequence of shell tasks in a YAML file and run them with a single command. Tasks execute sequentially; Luca stops at the first failure unless `continue-on-error` is set.

1. Create a pipeline file — either in the current directory or in a `pipelines/` subdirectory:

```yaml
---
parameters:
  - name: configuration
    description: Build configuration
    default: debug
  - name: upload
    description: Upload the build artifact after building
    default: "false"

tasks:
  - name: Build
    command: swift build --configuration ${configuration}

  - name: Test
    command: swift test
    when: ${configuration} == debug

  - name: Upload artifact
    command: ./scripts/upload.sh
    when: ${upload} == true
    continue-on-error: true
```

2. Run it by name (no path or extension needed):

```bash
luca run build
```

Or provide an explicit path:

```bash
luca run --file pipelines/release.yml
```

Pass parameter values at runtime with `--param` (or its short form `-p`):

```bash
luca run build --param configuration=release --param upload=true
luca run build -p configuration=release -p upload=true
```

Preview what would happen without executing anything:

```bash
luca run build --dry-run --param configuration=release
```

#### Parameters

Declare parameters in the `parameters:` block. Reference them in any task command with `${name}`. Parameters with a `default:` are optional; those without one are required — Luca exits with an error if no value is supplied via `--param`.

#### Params file

Store parameter values in a YAML file and pass it with `--params-file`:

```yaml
# build.params.yml
params:
  - key: configuration
    value: release
  - key: upload
    value: "true"
```

```bash
luca run build --params-file build.params.yml
```

Luca also looks for a params file automatically by convention (`<name>.params.yml`, `<name>.params`, `pipelines/<name>.params.yml`, `pipelines/<name>.params`). Values from `--param` override values from the params file.

#### Env file

Inject environment variables into every task from a dotenv file:

```bash
# .env
CI=true
DEVELOPER_DIR=/Applications/Xcode.app
```

```bash
luca run build --env-file .env
```

Luca loads `.env` from the current directory automatically when it exists. Use `--env-file` to point to a different file.

#### Conditions (`when`)

Use `when:` on any task to skip it conditionally. Supported forms:

| Expression | Behaviour |
|---|---|
| `${name} == value` | Run if the parameter equals `value` |
| `${name} != value` | Run if the parameter does not equal `value` |
| `${name}` | Run if the parameter is truthy (non-empty, not `false` or `0`) |

#### Pipeline file format reference

| Field | Level | Description |
|---|---|---|
| `tasks` | pipeline | Ordered list of tasks (required) |
| `parameters` | pipeline | Declared input parameters |
| `env` | pipeline | Environment variables applied to every task |
| `working-directory` | pipeline | Default working directory for all tasks |
| `name` | task | Human-readable label (required) |
| `command` | task | Shell command to execute (required) |
| `tools` | task | Explicit list of tools to validate before execution |
| `env` | task | Per-task environment variables (merged on top of pipeline-level env) |
| `working-directory` | task | Overrides the pipeline-level working directory |
| `when` | task | Condition expression; task is skipped when it evaluates to false |
| `continue-on-error` | task | When `true`, a non-zero exit is logged as a warning and execution continues |

## How It Works

### Binary tools

Luca performs the following steps:

1. Reads the tool specifications from your Lucafile
2. Downloads the specified zip files if they're not already installed
3. Extracts the binaries to `~/.luca/tools/{tool-name}/{version}/`
4. Creates symlinks in `.luca/tools/` in your current directory
5. Tools can then be accessed via `.luca/tools/{binary-name}`

### Agentic skills

For skills, Luca:

1. Reads the skill specifications from your Lucafile (or accepts a repository directly)
2. Clones or pulls the skill repository
3. Stores skill files in `.luca/skills/` in the current project and symlinks them into agent-specific directories (e.g. `.claude/skills/`, `.cursor/skills/`)
4. Skills are immediately available to the configured AI coding agents

## Lucafile Format

Luca looks for a spec file in the current directory using the following priority: `Lucafile`, `Lucafile.yml`, `Toolfile`, `Toolfile.yml`, `Skillfile`, `Skillfile.yml`. The alternative names are convenient when you want to keep tool and skill definitions in separate files, but the format is the same regardless of the file name — any spec file can contain both `tools:` and `skills:` sections.

The spec file is a YAML file with the following structure:

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
