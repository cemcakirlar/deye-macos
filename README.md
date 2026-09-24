# Deye Solar Monitor for macOS

A modern, lightweight, native macOS menu bar and desktop monitoring application for Deye solar inverters and home energy storage systems.

Seamlessly integrates with the DeyeCloud Open API (EU region) to display live PV production, household consumption, grid feed-in/purchase, and battery status directly in the macOS menu bar and in an elegant desktop dashboard window.

---

## Features

- **Menu Bar Monitoring:**
  - Live solar generation and battery state of charge (SOC): `☀️ 2.4 kW · 🔋 85%`
  - Multiple display modes: *Solar & Battery*, *Solar Only*, *Full Summary*, or *Icon Only*.
  - Fast, responsive popover dashboard when clicking the menu bar icon.
- **Dual Display Modes (Menu Bar & Independent Desktop Window):**
  - Use it as an unobtrusive menu bar companion or open a full desktop dashboard.
  - Interactive live energy flow diagram (PV Array ➔ Inverter ➔ Grid / Home / Battery directional arrows and real-time power readings).
- **Real-Time Energy Metrics:**
  - Solar generation (PV - W / kW)
  - Battery State of Charge (SOC %) with dynamic gradient indicators
  - Battery charge / discharge power (W)
  - Household consumption (W)
  - Grid import / export power (W)
- **Security-First Architecture:**
  - Sensitive credentials (App Secret, password, API tokens) are securely stored in the sandboxed application container; no external password prompt interruptions.
  - Password hashing via CryptoKit SHA-256 hex compliant with DeyeCloud API specifications.
  - Strict App Sandbox entitlement (`com.apple.security.network.client`) allowing outgoing API connections only.
- **Multi-Station Support:**
  - Automatic detection of multiple power stations linked to your account with a quick station switcher (`StationPickerView`).
  - Automatically selects single-station setups.
- **Automatic & Manual Refresh:**
  - Configurable background refresh intervals: 1m, 3m, 5m (default), 10m, 15m, or 30m.
  - One-click immediate manual refresh button.
  - Visual stale data indicators (warning when data is older than 15 minutes) with relative timestamps.

---

## Technology Stack

| Component | Technology |
|---|---|
| **Language** | Swift 6 (Strict Concurrency Safe) |
| **User Interface** | SwiftUI (macOS 14.0+ Sonoma / macOS 15.0+ Sequoia) |
| **macOS Native Components** | MenuBarExtra (.window), WindowGroup, SF Symbols |
| **Networking & API** | URLSession (async/await), Codable JSON |
| **Cryptography & Storage** | Apple CryptoKit (SHA-256), App Sandboxed Local Storage |
| **Build System** | Xcode Project (`DeyeMacOS.xcodeproj`) & Swift Package Manager (`Package.swift`) |

---

## Project Structure

```
deye-macos/
├── scripts/
│   ├── build.sh                 # Debug/Release compilation script
│   ├── run.sh                   # App build and launch script
│   ├── stop.sh                  # Process termination script
│   ├── install.sh               # Install to /Applications script
│   ├── package.sh               # Release distribution packaging (.zip + .sha256)
│   ├── release.sh               # End-to-end automated release cycle orchestrator
│   └── logs.sh                  # Live unified system log streaming script
├── dist/                        # Release distribution archives and checksums (git-ignored)
├── CHANGELOG.md                 # Keep a Changelog & Conventional Commits changelog
├── Makefile                     # CLI shortcuts (run, stop, install, package, release-*)
├── DeyeMacOS.xcodeproj/         # Xcode project bundle
│   └── project.pbxproj
├── DeyeMacOS/
│   ├── App/
│   │   ├── DeyeMacOSApp.swift   # App lifecycle, Window & MenuBarExtra definitions
│   │   └── AppState.swift       # ObservableObject, state management & polling logic
│   ├── Models/
│   │   ├── DeyeModels.swift     # API DTO models, Credentials, MenuBarDisplayMode
│   │   └── StationSnapshot.swift# Normalized real-time energy snapshot model
│   ├── Services/
│   │   ├── DeyeAPI.swift        # URLSession async/await client with 401 auto-retry
│   │   ├── CredentialStore.swift# Sandboxed persistent credential store
│   │   ├── CryptoHelper.swift   # CryptoKit SHA-256 hex utilities
│   │   └── Formatters.swift     # Power (W/kW), percentage, and timestamp formatters
│   ├── Views/
│   │   ├── MainDashboardView.swift  # Expanded desktop dashboard window
│   │   ├── MenuBarLabelView.swift   # Menu bar live status label (☀️/🔋)
│   │   ├── MenuBarPopoverView.swift # Menu bar quick popup view
│   │   ├── LoginView.swift          # Authentication screen
│   │   ├── StationPickerView.swift  # Multi-station switcher modal
│   │   ├── SettingsView.swift       # Settings & About sheet (Cmd + ,)
│   │   └── Components/
│   │       ├── EnergyCard.swift     # Metric status card component
│   │       ├── BatterySOCView.swift # Battery charge bar indicator
│   │       └── PowerFlowDiagram.swift # Dynamic animated energy flow diagram
│   └── Resources/
│       ├── Info.plist               # App metadata (version linked to build settings)
│       ├── DeyeMacOS.entitlements   # App Sandbox & Network Client entitlements
│       └── Assets.xcassets/         # App icons and theme accent colors
├── Package.swift                # Swift Package Manager manifest
└── README.md
```

---

## Build, Run, and Installation

You can build, run, and manage the project directly from the terminal without opening Xcode:

### 1. Developer CLI Shortcuts (Make)

```bash
# Show available commands (Default when running 'make'):
make

# Build Debug configuration and launch in background:
make run

# Run in foreground with live console output:
make run-fg

# Terminate running app instance:
make stop

# Compile in Debug mode only:
make build

# Compile in Release (Production) mode only:
make release

# Package distribution archive (.zip & .sha256) under dist/:
make package

# Stream live system logs:
make logs

# Clean build artifacts (DerivedData cache):
make clean
```

### 2. Permanent macOS Installation (Production)

To install the app directly into your system's `/Applications` directory:

```bash
make install
# or: ./scripts/install.sh --release
```

This automated installation:
1. Compiles the app in **Release (Production)** configuration.
2. Performs local macOS ad-hoc code signing and clears Gatekeeper quarantine flags.
3. Installs the bundle into **`/Applications/Deye Solar Monitor.app`**.
4. Registers with macOS LaunchServices so it appears instantly in **Spotlight (Cmd + Space)** and **Launchpad**.
5. Starts the menu bar app.

> **Tip:** To automatically launch on system boot, go to: *System Settings ➔ General ➔ Login Items* and add `Deye Solar Monitor`.

### 3. Installing from GitHub Releases (macOS Gatekeeper)

When downloading the `.zip` archive via a web browser from [GitHub Releases](https://github.com/cemcakirlar/deye-macos/releases), macOS attaches a `com.apple.quarantine` attribute. Because this is an open-source community app built without an Apple Developer ID ($99/year fee), macOS displays:
> *“Deye Solar Monitor” Not Opened — Apple could not verify “Deye Solar Monitor” is free of malware...*

**To open the app immediately:**
- **Option A (Fastest - Terminal):** Run this one-time command:
  ```bash
  xattr -cr "/Applications/Deye Solar Monitor.app"
  ```
- **Option B (macOS GUI):**
  1. Open **System Settings** ➔ **Privacy & Security**.
  2. Scroll down to the **Security** section.
  3. Click **Open Anyway** next to the *"Deye Solar Monitor"* notice and confirm.

---

## Initial Setup & Configuration

Upon first launch, enter your DeyeCloud API developer credentials:

1. **App ID:** Your App ID from the DeyeCloud Developer Portal.
2. **App Secret:** Your App Secret from the DeyeCloud Developer Portal.
3. **Email / Username:** Your Deye registered user account.
4. **Password:** Your Deye account password.

Credentials are saved in the app's sandboxed storage. Subsequent launches will automatically log in and begin streaming data without prompting.

---

## Release Management & Release Cycle

The project adheres to **[Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html)**, **[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)**, **[Keep a Changelog](https://keepachangelog.com/en/1.1.0/)**, and **GitHub Releases** standards.

### Single-Command Release Orchestration

Run any of the following commands to execute the full release cycle in a single automated step:

```bash
# 1. Patch Release (Bug fixes: e.g. 1.0.0 -> 1.0.1)
make release-patch

# 2. Minor Release (Backwards-compatible features: e.g. 1.0.0 -> 1.1.0)
make release-minor

# 3. Major Release (Breaking/architectural changes: e.g. 1.0.0 -> 2.0.0)
make release-major

# 4. Explicit Version Specification
make release-publish VERSION=1.2.0

# 5. Safe Simulation (Dry-Run: tests the cycle without applying changes or pushing)
make release-dry-run
```

### What Happens During the Release Cycle?

1. **Preflight Checks:** Validates clean git working tree, active `main` branch, and availability of required tools (`gh`, `xcodebuild`, `ditto`, `shasum`).
2. **Version Bump:** Updates `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` (build number) in `DeyeMacOS.xcodeproj/project.pbxproj`.
3. **Dynamic UI Synchronization:** The application UI dynamically reads the version string from the main bundle.
4. **Changelog & Release Notes Generation:** Automatically parses Conventional Commits (`feat:`, `fix:`, `perf:`, `chore:`, etc.) since the previous git tag and prepends the categorized release notes to `CHANGELOG.md`.
5. **Production Build & Artifact Packaging:**
   - Compiles in Release mode.
   - Archives the `.app` bundle via Apple's official `ditto -c -k --keepParent` command to preserve permissions, symlinks, and macOS metadata into `dist/Deye-Solar-Monitor-vX.Y.Z-macOS.zip`.
   - Computes SHA-256 integrity checksum into `dist/Deye-Solar-Monitor-vX.Y.Z-macOS.zip.sha256`.
6. **Git Commit & Tag:**
   - Commits version bumps with `chore(release): vX.Y.Z`.
   - Creates an annotated Git tag `vX.Y.Z`.
7. **Git Push & GitHub Release:**
   - Pushes commits and tags to the remote repository.
   - Uses `gh release create` to publish the official GitHub Release with release notes, zip archive, and SHA-256 checksum asset attached.

---

## License

Personal and private utility application. All rights reserved.
