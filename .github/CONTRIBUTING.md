# Contributing to Luca

First off, thank you for considering contributing to Luca! It's people like you that make Luca such a great tool.

Following these guidelines helps to communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue, assessing changes, and helping you finalize your pull requests.

## Code of Conduct

This project and everyone participating in it is governed by the Luca Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Getting Started

Contributions to Luca can come in many forms. You can help with:

- Reporting bugs
- Suggesting features
- Writing or improving documentation
- Fixing bugs
- Implementing features
- Reviewing code
- Answering questions

### Prerequisites

Before you begin contributing, ensure you have:

- Git installed
- Swift 5.7 or later
- Xcode (if developing on macOS)
- A GitHub account

### Development Environment Setup

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```
   git clone https://github.com/YOUR-USERNAME/Luca.git
   cd Luca
   ```
3. Add the original repository as a remote to keep your fork in sync:
   ```
   git remote add upstream https://github.com/LucaTools/Luca.git
   ```
4. Create a branch for your work:
   ```
   git checkout -b feature/your-feature-name
   ```

## Making Changes

### Coding Standards

- Follow Swift's official style guide
- Write clear, readable code with descriptive names
- Add comments where necessary
- Write unit tests for new features

### Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

Example:
```
Add support for downloading from private repositories

This adds authentication options when specifying ZIP URLs.
Fixes #123
```

### Testing

- Add tests for any new features or bug fixes
- Ensure all existing tests pass before submitting your changes
- Run `swift test` to execute tests

## Submitting Changes

1. Push your changes to your fork:
   ```
   git push origin feature/your-feature-name
   ```

2. Submit a pull request through the GitHub website:
   - Go to your fork on GitHub
   - Select your branch
   - Click 'Pull Request'
   - Fill out the pull request template with details about your changes

3. Request a code review from one of the maintainers

## Pull Request Process

1. Update the README.md or documentation with details of changes to the interface, if applicable
2. Update the CHANGELOG.md with details of your changes
3. The pull request will be merged once it has been approved by a maintainer

## Release Process

Luca follows [Semantic Versioning](https://semver.org/). The release process is handled by the maintainers.

## Resources

- [Issue tracker](https://github.com/LucaTools/Luca/issues)
- [Documentation](https://github.com/LucaTools/Luca/wiki)

## Recognition

Contributors will be recognized in the project's README and CHANGELOG.

Thank you for contributing to Luca!
