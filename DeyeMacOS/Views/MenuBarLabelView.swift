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
        .id("menubar_label_\(appState.menuBarDisplayMode.rawValue)_\(appState.gridImportThresholdW)_\(appState.gridExportThresholdW)_\(appState.batteryChargeThresholdW)_\(appState.batteryDischargeThresholdW)_\(appState.snapshot?.fetchedAtEpochMs ?? 0)")
    }

    @ViewBuilder
    private func content(for snapshot: StationSnapshot) -> some View {
        let solar = Formatters.compactPower(snapshot.generationPowerW)
        let soc = Formatters.percentage(snapshot.batterySocPercent)
        let home = Formatters.compactPower(snapshot.consumptionPowerW)

        let gridImportTh = appState.gridImportThresholdW
        let gridExportTh = appState.gridExportThresholdW
        let battChargeTh = appState.batteryChargeThresholdW

        let effectiveGrid = snapshot.effectiveGridPower(importThreshold: gridImportTh, exportThreshold: gridExportTh)
        let gridText = Formatters.compactPower(abs(effectiveGrid))
        let isCharging = snapshot.isCharging(threshold: battChargeTh)
        let battEmoji = isCharging ? "⚡️🔋" : "🔋"

        switch appState.menuBarDisplayMode {
        case .solarAndBattery:
            Text("☀️ \(solar)  \(battEmoji) \(soc)")

        case .solarOnly:
            Text("☀️ \(solar)")

        case .fullSummary:
            let isSelling = effectiveGrid <= -gridExportTh
            let isBuying = effectiveGrid >= gridImportTh
            let gridEmoji = isSelling ? "⚡️↗" : (isBuying ? "⚡️↘" : "⚡️")
            Text("☀️ \(solar)  \(battEmoji) \(soc)  🏠 \(home)  \(gridEmoji) \(gridText)")

        case .iconOnly:
            Text("☀️")
        }
    }
}
