import SwiftUI
import AppKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        WindowManager.shared.showMainWindow()
        return true
    }

    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        WindowManager.shared.isTerminating = true
        return .terminateNow
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
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
