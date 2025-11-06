# Development Lifecycle

This page documents the Development Lifecycle and Release Strategy for the Godot Asset Placer Plugin.

## Versioning

The plugin follows [Semantic Versioning](https://semver.org/) (SemVer) with the format: `MAJOR.MINOR.PATCH[-PRERELEASE]`

- **MAJOR**: Incremented for incompatible API changes or major feature additions
- **MINOR**: Incremented for new features that are backward compatible
- **PATCH**: Incremented for backward-compatible bug fixes and small features
- **PRERELEASE** (optional): Indicates pre-release versions (alpha, beta, rc)

### Pre Releases
Godot Asset Placer has the following pre-releases that are part of the release lifecycle:
- `Alpha` - The most early version of the update usually containing **new** features that are already in a usable state. Each `Alpha` release can contain multiple new feature.  Bugs and Changes to these features are expected
- `Beta` - Next stable version after `Alpha`. Release reaching `Beta` usually means the release scope is done and no major changes or additions will follow. Minor bugs are expected
- `State` (no identifier) - All features reached its stable status, potential issues will be addressed in PATCH versions

## Update Channels

Users can configure which release channel they want to receive updates from in the plugin's Settings Panel:

- **Stable Channel**: Only receives stable releases (Default)
- **Beta Channel**: Receives both stable and beta releases
- **Alpha Channel**: Receives all releases (stable, beta, and alpha)

The in-editor updater automatically filters available releases based on the selected channel.

Each version typically goes through multiple alpha and beta releases before reaching stability.