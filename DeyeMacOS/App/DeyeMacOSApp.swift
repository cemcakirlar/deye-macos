import SwiftUI
import AppKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static var hasHandledAppLaunch: Bool = false

    public func applicationDidFinishLaunching(_ notification: Notification) {
        Self.handleInitialWindowVisibility()
    }

    public static func handleInitialWindowVisibility() {
        guard !hasHandledAppLaunch else { return }
        hasHandledAppLaunch = true

        let showOnLaunch = UserDefaults.standard.bool(forKey: "deye_show_main_window_on_launch")
        if !showOnLaunch {
            DispatchQueue.main.async {
                for window in NSApplication.shared.windows {
                    if window.identifier?.rawValue == "main" || window.title.contains("Deye Solar") {
                        window.close()
                    }
                }
            }
        }
    }
}

@main
public struct DeyeMacOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    public init() {}

    public var body: some Scene {
        // Main Application Window (Single instance window)
        Window("Deye Solar Monitor", id: "main") {
            MainDashboardView(appState: appState)
                .environmentObject(appState)
        }
        .defaultSize(width: 880, height: 620)
        .windowResizability(.contentMinSize)

        // Menu Bar Status Item & Popover
        MenuBarExtra {
            MenuBarPopoverView(appState: appState)
                .environmentObject(appState)
        } label: {
            MenuBarLabelView(appState: appState)
        }
        .menuBarExtraStyle(.window)

        // macOS Settings (Preferences - Cmd + ,)
        Settings {
            SettingsView(appState: appState)
                .environmentObject(appState)
        }
    }
}
