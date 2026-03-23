# ``LucaCore``

A lightweight tool manager for macOS and Linux that helps developers install, manage, and activate specific versions of development tools.

## Overview

Luca helps you manage command-line tools by downloading, verifying, and installing binaries from GitHub releases. Define your tools in a `Lucafile` and let Luca handle the rest.

### Key Features

- **Version-specific installations**: Install specific versions of tools needed for your project
- **Project isolation**: Each project can have its own set of active tools
- **Simple specification**: Define required tools in a simple YAML file (Lucafile)
- **Zero configuration**: Just create a Lucafile and run `luca install`
- **No PATH pollution**: Tools are symlinked locally in your project directory
- **Idempotent operations**: Safe to run multiple times

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Lucafile>

### Tutorials

- <doc:Luca>

### Contributing

- <doc:Contributing>

### Core Components

- ``Installer``
- ``SymLinker``
- ``SpecLoader``
- ``Tool``
- ``Spec``
- ``Skill``

### Skills

- ``SkillInstaller``

### Downloading and Extraction

- ``Downloader``
- ``Unarchiver``
- ``FileTypeDetector``

### Validation

- ``ChecksumValidator``
- ``ChecksumCalculator``
- ``ArchitectureValidator``

### Tool Management

- ``InstalledToolsLister``
- ``LinkedToolsLister``
- ``Uninstaller``
- ``Unlinker``

### Git Integration

- ``GitHookInstaller``
- ``GitIgnoreManager``

### GitHub Integration

- ``GitHubReleaseURLFactory``
- ``ReleaseInfoProvider``

### Utilities

- ``PermissionManager``
- ``Printer``
- ``BinaryFinder``
- ``ToolFactory``
- ``VersionLister``
