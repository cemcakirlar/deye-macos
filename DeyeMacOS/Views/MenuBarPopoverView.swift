import SwiftUI

public struct MenuBarPopoverView: View {
    @ObservedObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.selectedStationName.isEmpty ? "Deye Solar" : appState.selectedStationName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)

                    if let snapshot = appState.snapshot {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(snapshot.isStale ? Color.orange : Color.green)
                                .frame(width: 6, height: 6)

                            Text(snapshot.isStale ? "Eski veri · \(Formatters.time(snapshot.lastUpdateDate))" : "Güncel · \(Formatters.time(snapshot.lastUpdateDate))")
                                .font(.caption2)
                                .foregroundStyle(snapshot.isStale ? .orange : .secondary)
                        }
                    } else {
                        Text("Veri bekleniyor...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    Task {
                        await appState.refresh()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold))
                        .rotationEffect(.degrees(appState.isLoading ? 360 : 0))
                        .animation(appState.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: appState.isLoading)
                }
                .buttonStyle(.plain)
                .padding(6)
                .background(Color.primary.opacity(0.06))
                .clipShape(Circle())
                .disabled(appState.isLoading || !appState.isLoggedIn)
                .help("Anlık veriyi yenile")
            }

            // Quick Station Switcher Tabs (when user has multiple stations)
            if appState.stations.count > 1 {
                Picker("Santral", selection: Binding(
                    get: { appState.selectedStationId ?? 0 },
                    set: { newId in
                        if let target = appState.stations.first(where: { $0.resolvedId == newId }) {
                            Task {
                                await appState.selectStation(target)
                            }
                        }
                    }
                )) {
                    ForEach(appState.stations, id: \.resolvedId) { station in
                        Text(station.displayName).tag(station.resolvedId ?? 0)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            if !appState.isLoggedIn {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)

                    Text("DeyeCloud Hesabı Bağlı Değil")
                        .font(.headline)

                    Text("Güneş ve batarya durumunu takip etmek için lütfen giriş yapın.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Giriş Ekranını Aç") {
                        openMainWindow()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 20)
            } else {
                if let err = appState.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(err)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .lineLimit(2)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                let snapshot = appState.snapshot
                let gridImportTh = appState.gridImportThresholdW
                let gridExportTh = appState.gridExportThresholdW
                let battChargeTh = appState.batteryChargeThresholdW
                let battDischargeTh = appState.batteryDischargeThresholdW
                let isCharging = snapshot?.isCharging(threshold: battChargeTh) ?? false
                let isDischarging = snapshot?.isDischarging(threshold: battDischargeTh) ?? false
                let effectiveGrid = snapshot?.effectiveGridPower(importThreshold: gridImportTh, exportThreshold: gridExportTh) ?? 0
                let effectiveBatt = snapshot?.effectiveBatteryPower(chargeThreshold: battChargeTh, dischargeThreshold: battDischargeTh) ?? 0

                // Battery SOC Bar
                BatterySOCView(
                    socPercent: snapshot?.batterySocPercent,
                    powerW: abs(effectiveBatt),
                    isCharging: isCharging,
                    isDischarging: isDischarging
                )

                // 2x2 Grid for Key Metrics
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    EnergyCard(
                        title: "Güneş (PV)",
                        icon: "sun.max.fill",
                        valueText: Formatters.power(snapshot?.generationPowerW),
                        subtitle: (snapshot?.generationPowerW ?? 0) > 10 ? "Aktif Üretim" : "Gece / Beklemede",
                        tintColor: .orange,
                        isEmphasized: (snapshot?.generationPowerW ?? 0) > 10
                    )

                    EnergyCard(
                        title: "Ev Tüketimi",
                        icon: "house.fill",
                        valueText: Formatters.power(snapshot?.consumptionPowerW),
                        subtitle: "Anlık Yük",
                        tintColor: .purple
                    )

                    let isSelling = effectiveGrid <= -gridExportTh
                    let isBuying = effectiveGrid >= gridImportTh

                    EnergyCard(
                        title: "Şebeke",
                        icon: "bolt.fill",
                        valueText: Formatters.power(abs(effectiveGrid)),
                        subtitle: isSelling ? "Şebekeye Satış" : (isBuying ? "Şebekeden Alış" : "Dengeli (0 W)"),
                        tintColor: isSelling ? .green : (isBuying ? .blue : .secondary)
                    )

                    EnergyCard(
                        title: "Batarya Gücü",
                        icon: isCharging ? "arrow.down.forward" : "arrow.up.forward",
                        valueText: Formatters.power(abs(effectiveBatt)),
                        subtitle: isCharging ? "Şarj Ediliyor" : (isDischarging ? "Deşarj Oluyor" : "Durağan (0 W)"),
                        tintColor: isCharging ? .green : (isDischarging ? .orange : .secondary)
                    )
                }
            }

            Divider()

            // Footer Actions
            HStack {
                Button("Ana Pencere") {
                    openMainWindow()
                }
                .buttonStyle(.link)
                .font(.caption)

                if appState.stations.count > 1 {
                    Text("·").foregroundStyle(.secondary)
                    Button("İstasyon Değiştir") {
                        openMainWindow()
                        appState.needsStationSelection = true
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }

                Spacer()

                Button("Çıkış") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.link)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 360)
    }

    private func openMainWindow() {
        if WindowManager.shared.mainWindow == nil {
            openWindow(id: "main")
        }
        WindowManager.shared.showMainWindow()
    }
}
