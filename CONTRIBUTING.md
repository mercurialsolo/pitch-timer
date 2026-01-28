# Contributing to PitchTimer

Thank you for your interest in contributing to PitchTimer! This document provides guidelines for contributing to the project.

## Code of Conduct

Please be respectful and constructive in all interactions. We're building a welcoming community.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Description**: Clear description of the bug
- **Steps to Reproduce**: Numbered steps to reproduce the behavior
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **System Info**: macOS version, PitchTimer version
- **Screenshots**: If applicable

### Suggesting Features

Feature suggestions are welcome! Please:

- Check if the feature has already been suggested
- Provide a clear use case
- Explain why this feature would be useful to most users
- Consider if it fits the app's philosophy (simple, unobtrusive timer)

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Follow the coding style**: See CLAUDE.md for patterns
4. **Test your changes**: Ensure the app builds and works as expected
5. **Commit your changes**: `git commit -m 'Add amazing feature'`
6. **Push to your fork**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

### Development Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/pitch-timer.git
cd pitch-timer/PitchTimer

# Build the project
swift build

# Run the app
swift run
```

### Coding Guidelines

- **Follow existing patterns**: Study CLAUDE.md for architecture
- **Keep it simple**: Avoid over-engineering
- **Test your code**: Run the app and test all affected features
- **Document your changes**: Update README.md and CLAUDE.md if needed
- **Use meaningful commits**: Write clear commit messages

### Code Style

- Use Swift naming conventions
- Keep functions focused and small
- Add comments for complex logic
- Use delegates for communication between components
- Follow the existing MVC-like pattern

### Pull Request Checklist

- [ ] Code builds without warnings
- [ ] App runs and features work as expected
- [ ] Documentation updated (README.md, CLAUDE.md)
- [ ] No breaking changes (unless discussed)
- [ ] Commit messages are clear
- [ ] PR description explains what and why

## Project Structure

See CLAUDE.md for detailed architecture documentation.

Key components:
- **AppDelegate**: Main coordinator
- **TimerManager**: Core timer logic
- **TimerWindowController**: Overlay window
- **HotkeyManager**: Global keyboard shortcuts
- **NetworkSyncManager**: Peer-to-peer sync
- **SettingsWindowController**: Preferences UI

## Feature Philosophy

PitchTimer aims to be:
- **Simple**: Easy to understand and use
- **Unobtrusive**: Lives in menu bar, minimal UI
- **Focused**: Does one thing (timing) really well
- **Keyboard-friendly**: Full keyboard control
- **Reliable**: Perfect time sync, no drift

When proposing features, consider if they align with these principles.

## Questions?

Feel free to open an issue with the "question" label.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
