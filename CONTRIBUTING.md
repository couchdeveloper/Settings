# Contributing to Settings

Thank you for your interest in contributing to Settings! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Bugs

Before creating a bug report, please check existing issues to avoid duplicates.

When filing a bug report, include:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected vs actual behavior
- Swift version and platform (iOS/macOS/etc.)
- Code samples if applicable
- Any relevant error messages or logs

### Suggesting Features

Feature suggestions are welcome! Please:
- Check if the feature has already been suggested
- Clearly describe the feature and its use case
- Explain why it would be valuable to the project
- Provide examples if possible

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Write tests** for any new functionality
3. **Ensure all tests pass**: `swift test`
4. **Follow Swift style guidelines**: Use SwiftLint if available
5. **Update documentation** if you're changing APIs
6. **Write a clear PR title** that will serve as the changelog entry
7. **Add a label** to categorize the change:
   - `breaking` - Breaking API changes (major version bump)
   - `enhancement` - New features or improvements (minor version bump)
   - `bug` - Bug fixes (patch version bump)
   - `documentation` - Documentation-only changes (no version bump)
   - `not-included-in-release` - Explicitly exclude from release (e.g., internal refactoring, experiments)

**Note**: Pull requests will be squash-merged, so multiple commits in your branch will become a single commit on `main`. By default, all merged PRs are included in releases unless marked with `not-included-in-release`. The PR title and label determine the changelog entry and version bump.

#### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/Settings.git
cd Settings

# Build the project
swift build

# Run tests
swift test

# Run specific tests
swift test --filter SettingsTests
```

#### Code Style

- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Keep functions focused and concise
- Prefer Swift 6 concurrency features (async/await, actors)

#### Testing

- Write unit tests for new features
- Ensure existing tests continue to pass
- Test on multiple platforms when possible
- Include tests for edge cases and error conditions

### Submitting Changes

1. Push your changes to your fork
2. Create a Pull Request with:
   - Clear title describing the change
   - Description of what changed and why
   - Reference to any related issues
   - Screenshots if UI-related

3. Wait for review and address any feedback

## Project Structure

```
Settings/
├── Sources/
│   ├── Settings/           # Main library
│   │   ├── MacroSetting/   # Attribute protocols and implementations
│   │   ├── MacroSettings/  # Container protocols
│   │   ├── SwiftUI/        # SwiftUI integration
│   │   └── Combine/        # Reactive extensions
│   ├── SettingsMacros/     # Macro implementations
│   ├── SettingsMock/       # Testing utilities
│   └── SettingsClient/     # Example usage
├── Tests/
│   ├── SettingsTests/      # Runtime tests
│   └── SettingsMacroExpansionTests/  # Macro expansion tests
└── Development/
    └── Design Concepts/    # Design documentation
```

## Development Guidelines

### Macros

- Macro implementations are in `SettingsMacros/`
- Test macro expansions in `SettingsMacroExpansionTests/`
- Ensure good error messages with fix-its when possible

### Runtime Code

- Keep thread-safety in mind (use `@unchecked Sendable` carefully)
- Maintain compatibility with Swift 6 strict concurrency
- Optimize for common use cases (property list types)

### Documentation

- Use Swift documentation comments (`///`)
- Include code examples for complex features
- Keep README.md up to date
- Update CHANGELOG.md for notable changes

## Questions?

Feel free to open an issue for questions or discussions about the project.

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
