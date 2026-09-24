import SwiftUI

@main
public struct DeyeMacOSApp: App {
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
