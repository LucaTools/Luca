# Contributing to Luca

Learn how to contribute to the Luca project.

## Overview

Thank you for considering contributing to Luca! This guide will help you get started with the development process.

## Ways to Contribute

- Reporting bugs
- Suggesting features
- Writing or improving documentation
- Fixing bugs
- Implementing features
- Reviewing code
- Answering questions

## Prerequisites

Before you begin contributing, ensure you have:

- Git installed
- Swift 5.7 or later
- Xcode (for developing on macOS)
- A GitHub account

## Development Environment Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR-USERNAME/Luca.git
cd Luca
```

### 2. Add Upstream Remote

```bash
git remote add upstream https://github.com/LucaTools/Luca.git
```

### 3. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

## Building and Testing

### Build the Project

```bash
swift build
```

### Run Tests

```bash
swift test
```

### Build Documentation Locally

```bash
swift package --disable-sandbox preview-documentation --target LucaCore
```

This starts a local server at `http://localhost:8000` where you can preview the documentation.

## Code Style Guidelines

- Follow Swift's official style guide
- Write clear, readable code with descriptive names
- Add comments where necessary
- Write unit tests for new features

## Commit Message Guidelines

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests after the first line

### Example Commit Message

```
Add support for downloading from private repositories

This adds authentication options when specifying ZIP URLs.
Fixes #123
```

## Submitting Changes

### 1. Push Your Changes

```bash
git push origin feature/your-feature-name
```

### 2. Create a Pull Request

1. Go to your fork on GitHub
2. Select your branch
3. Click 'Pull Request'
4. Fill out the pull request template

### 3. Code Review

Request a code review from one of the maintainers.

## Pull Request Checklist

- [ ] Update documentation if interface changes
- [ ] Add tests for new functionality
- [ ] Ensure all tests pass
- [ ] Update CHANGELOG.md with your changes

## Architecture Overview

### Project Structure

```
Sources/
├── LucaCLI/          # Command-line interface
│   └── Commands/     # CLI commands (install, uninstall, etc.)
└── LucaCore/         # Core library
    ├── Core/         # Core functionality
    └── Models/       # Data models
```

### Key Components

- **Installer**: Orchestrates the tool installation process
- **SpecLoader**: Parses Lucafile configurations
- **Downloader**: Handles file downloads from URLs
- **Unarchiver**: Extracts archives (ZIP, tar.gz)
- **SymLinker**: Creates symlinks in project directories

## Resources

- [Issue Tracker](https://github.com/LucaTools/Luca/issues)
- [Pull Request Template](https://github.com/LucaTools/Luca/blob/main/.github/PULL_REQUEST_TEMPLATE.md)

## Recognition

Contributors are recognized in the project's README and CHANGELOG.
