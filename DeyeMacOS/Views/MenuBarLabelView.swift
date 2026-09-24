import SwiftUI

public struct MenuBarLabelView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        Group {
            if !appState.isLoggedIn {
                Text("☀️ Deye")
            } else if let snapshot = appState.snapshot {
                content(for: snapshot)
            } else if appState.isLoading {
                Text("☀️ Deye...")
            } else {
                Text("☀️ Deye")
            }
        }
        .id("menubar_label_\(appState.menuBarDisplayMode.rawValue)_\(appState.snapshot?.fetchedAtEpochMs ?? 0)")
    }

    @ViewBuilder
    private func content(for snapshot: StationSnapshot) -> some View {
        let solar = Formatters.compactPower(snapshot.generationPowerW)
        let soc = Formatters.percentage(snapshot.batterySocPercent)
        let home = Formatters.compactPower(snapshot.consumptionPowerW)
        let gridPower = snapshot.wirePowerW ?? 0
        let grid = Formatters.compactPower(abs(gridPower))
        let battEmoji = snapshot.isCharging ? "⚡️🔋" : "🔋"

        switch appState.menuBarDisplayMode {
        case .solarAndBattery:
            Text("☀️ \(solar)  \(battEmoji) \(soc)")

        case .solarOnly:
            Text("☀️ \(solar)")

        case .fullSummary:
            let gridEmoji = gridPower > 20 ? "⚡️↗" : (gridPower < -20 ? "⚡️↘" : "⚡️")
            Text("☀️ \(solar)  \(battEmoji) \(soc)  🏠 \(home)  \(gridEmoji) \(grid)")

        case .iconOnly:
            Text("☀️")
        }
    }
}
