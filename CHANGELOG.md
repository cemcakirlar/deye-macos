# Changelog

All notable changes to the Deye Solar Monitor for macOS project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.0] - 2026-09-24

### 🚀 Features
- feat(release): add automated release cycle, packaging scripts, and English documentation (`b8f2c70`)
- feat(security): remove File.txt, update security disclaimer strings, and expand gitignore (`79bf026`)
- feat(assets): add custom macOS squircle app icon asset set (`a4cc0d9`)
- feat(scripts): add CLI build, run, stop, install scripts and Makefile (`51e59dd`)
- feat(ui): add launch window visibility preference with menu-bar-only default (`9a94188`)
- feat: add configurable power thresholds and station switcher to UI and snapshot models (`3b099d8`)
- feat: add multi-station switching, CredentialStore service, and configurable power thresholds (`410e83e`)
- feat: add initial Deye macOS application with SwiftUI and cloud API integration (`67b9bab`)



## [v1.0.0] - 2026-09-24

### 🚀 Added
- **app**: Initial release of Deye Solar Monitor native macOS menu bar application (`67b9bab`)
- **auth & storage**: Apple sandbox-secured CredentialStore with persistent session management (`410e83e`)
- **station switcher**: Multi-station discovery and quick switcher interface (`410e83e`)
- **thresholds**: Configurable grid power thresholds and dynamic solar status indicators (`3b099d8`)
- **window management**: Menu bar popover with configurable launch window visibility preferences (`9a94188`)
- **automation & scripts**: CLI build, run, stop, install, package, and release scripts with Makefile integration (`51e59dd`)
- **branding**: macOS HIG-compliant custom squircle application icon set (`a4cc0d9`)
- **security**: Security disclaimers, privacy policy strings, and expanded .gitignore rules (`79bf026`)
