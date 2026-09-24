# Changelog

All notable changes to the Deye Solar Monitor for macOS project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.2] - 2026-09-24

### ⚡ Performance & Refactoring
- refactor(window): improve main window management and settings integration (`a0d1f87`)
- refactor(window): own main window lifecycle in WindowManager (`0215dae`)
- refactor(settings): type settings behind AppConfig (`4b6fad9`)

### 🔧 Maintenance & Tooling
- docs: add window and settings refactor prompts (`159c653`)

---

### 🍏 macOS Installation & Gatekeeper Note
Because this open-source build is distributed outside the Mac App Store without a paid Apple Developer ID, macOS Gatekeeper may show a warning (*"Apple could not verify..."*) on first launch.

**To open the app, run this single command in Terminal:**
```bash
xattr -cr "/Applications/Deye Solar Monitor.app"
```
*Alternatively, open **System Settings ➔ Privacy & Security** and click **Open Anyway**.* 



## [v1.0.1] - 2026-09-24

### 🚀 Features
- feat: allow user-selected and custom Deye data centers at login (`ec79c29`)
- feat: add directional power thresholds and fix grid import/export sign convention (`3f62ec7`)

---

### 🍏 macOS Installation & Gatekeeper Note
Because this open-source build is distributed outside the Mac App Store without a paid Apple Developer ID, macOS Gatekeeper may show a warning (*"Apple could not verify..."*) on first launch.

**To open the app, run this single command in Terminal:**
```bash
xattr -cr "/Applications/Deye Solar Monitor.app"
```
*Alternatively, open **System Settings ➔ Privacy & Security** and click **Open Anyway**.* 



## [v1.0.0] - 2026-09-24

### 🚀 Features
- **license**: Open-sourced under the MIT License (`6e48380`)
- **app**: Initial release of Deye Solar Monitor native macOS menu bar application (`67b9bab`)
- **auth & storage**: Apple sandbox-secured CredentialStore with persistent session management (`410e83e`)
- **station switcher**: Multi-station discovery and quick switcher interface (`410e83e`)
- **thresholds**: Configurable grid power thresholds and dynamic solar status indicators (`3b099d8`)
- **window management**: Menu bar popover with configurable launch window visibility preferences (`9a94188`)
- **automation & scripts**: CLI build, run, stop, install, package, and release scripts with Makefile integration (`51e59dd`)
- **branding**: macOS HIG-compliant custom squircle application icon set (`a4cc0d9`)
- **security**: Security disclaimers, privacy policy strings, and expanded .gitignore rules (`79bf026`)
