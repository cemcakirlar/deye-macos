import AppKit
import Foundation
import ServiceManagement

/// Dock visibility and Open at Login helpers for menu-bar-first launch behavior.
public enum LaunchIntegration {
    /// Applies Dock visibility. `.accessory` hides the Dock icon (menu-bar agent);
    /// `.regular` shows it. Prefer calling from `applicationWillFinishLaunching`
    /// so the Dock does not flash on startup when hidden.
    @MainActor
    public static func applyDockVisibility(showInDock: Bool) {
        let policy: NSApplication.ActivationPolicy = showInDock ? .regular : .accessory
        _ = NSApp.setActivationPolicy(policy)
    }

    /// Treat enabled and pending-approval as "on" so the Settings toggle stays honest.
    public static var isOpenAtLoginEnabled: Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval:
            return true
        default:
            return false
        }
    }

    public static var openAtLoginRequiresApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    /// Registers or unregisters the main app as a Login Item via `SMAppService`.
    public static func setOpenAtLogin(_ enabled: Bool) throws {
        let service = SMAppService.mainApp
        if enabled {
            switch service.status {
            case .enabled, .requiresApproval:
                return
            default:
                try service.register()
            }
        } else {
            switch service.status {
            case .notRegistered:
                return
            default:
                try service.unregister()
            }
        }
    }
}
