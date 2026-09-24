import SwiftUI

public struct MainDashboardView: View {
    @ObservedObject var appState: AppState
    @State private var showingSettingsSheet: Bool = false
    @State private var showingStationPicker: Bool = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        Group {
            if !appState.isLoggedIn {
                LoginView(appState: appState)
            } else {
                dashboardContent
            }
        }
        .frame(minWidth: 720, minHeight: 520)
        .onAppear {
            AppDelegate.handleInitialWindowVisibility()
        }
        .sheet(isPresented: $appState.needsStationSelection) {
            StationPickerView(appState: appState)
        }
        .sheet(isPresented: $showingStationPicker) {
            StationPickerView(appState: appState)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView(appState: appState)
        }
    }

    private var dashboardContent: some View {
        VStack(spacing: 0) {
            // Top Toolbar / Header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(appState.selectedStationName.isEmpty ? "Deye Santral" : appState.selectedStationName)
                            .font(.title2)
                            .fontWeight(.bold)

                        if appState.stations.count > 1 {
                            Button {
                                showingStationPicker = true
                            } label: {
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Santral Değiştir")
                        }
                    }

                    if let snapshot = appState.snapshot {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(snapshot.isStale ? Color.orange : Color.green)
                                .frame(width: 7, height: 7)

                            Text(snapshot.isStale ? "Eski Veri · Son Güncelleme: \(Formatters.time(snapshot.lastUpdateDate))" : "Sistem Çevrimiçi · Son Güncelleme: \(Formatters.time(snapshot.lastUpdateDate))")
                                .font(.caption)
                                .foregroundStyle(snapshot.isStale ? .orange : .secondary)
                        }
                    } else {
                        Text("Veri bekleniyor...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        Task {
                            await appState.refresh()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .rotationEffect(.degrees(appState.isLoading ? 360 : 0))
                                .animation(appState.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: appState.isLoading)
                            Text(appState.isLoading ? "Yenileniyor..." : "Yenile")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.isLoading)

                    Button {
                        showingSettingsSheet = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(.bordered)
                    .help("Ayarlar")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(nsColor: .windowBackgroundColor))

            // Station Tabs Strip (visible when user has multiple stations)
            if appState.stations.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(appState.stations, id: \.resolvedId) { station in
                            let isSelected = (station.resolvedId == appState.selectedStationId)
                            Button {
                                Task {
                                    await appState.selectStation(station)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: isSelected ? "sun.max.fill" : "sun.max")
                                        .foregroundStyle(isSelected ? Color.orange : Color.secondary)
                                        .font(.system(size: 13, weight: .semibold))

                                    Text(station.displayName)
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                        .foregroundStyle(isSelected ? Color.primary : Color.secondary)

                                    if let id = station.resolvedId, let snap = appState.stationSnapshots[id], let pv = snap.generationPowerW {
                                        Text(Formatters.compactPower(pv))
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(isSelected ? Color.orange : Color.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(isSelected ? Color.orange.opacity(0.15) : Color.primary.opacity(0.06))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background {
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color(nsColor: .controlBackgroundColor))
                                            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                                            }
                                    } else {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.primary.opacity(0.04))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
            }

            Divider()

            // Main Body ScrollView
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    if let err = appState.errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(err)
                                .font(.callout)
                                .foregroundStyle(.red)
                            Spacer()
                            Button("Tekrar Dene") {
                                Task {
                                    await appState.refresh()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Top Row: Power Flow Diagram & Battery Gauge
                    HStack(alignment: .top, spacing: 20) {
                        PowerFlowDiagram(
                            snapshot: appState.snapshot,
                            gridImportThreshold: appState.gridImportThresholdW,
                            gridExportThreshold: appState.gridExportThresholdW,
                            batteryChargeThreshold: appState.batteryChargeThresholdW,
                            batteryDischargeThreshold: appState.batteryDischargeThresholdW
                        )
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 16) {
                            let snapshot = appState.snapshot
                            let gridImportTh = appState.gridImportThresholdW
                            let gridExportTh = appState.gridExportThresholdW
                            let battChargeTh = appState.batteryChargeThresholdW
                            let battDischargeTh = appState.batteryDischargeThresholdW

                            let effectiveGrid = snapshot?.effectiveGridPower(importThreshold: gridImportTh, exportThreshold: gridExportTh) ?? 0
                            let effectiveBatt = snapshot?.effectiveBatteryPower(chargeThreshold: battChargeTh, dischargeThreshold: battDischargeTh) ?? 0
                            let isCharging = snapshot?.isCharging(threshold: battChargeTh) ?? false
                            let isDischarging = snapshot?.isDischarging(threshold: battDischargeTh) ?? false

                            BatterySOCView(
                                socPercent: snapshot?.batterySocPercent,
                                powerW: abs(effectiveBatt),
                                isCharging: isCharging,
                                isDischarging: isDischarging
                            )

                            // 2x2 Metric Cards
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                EnergyCard(
                                    title: "Güneş (PV)",
                                    icon: "sun.max.fill",
                                    valueText: Formatters.power(snapshot?.generationPowerW),
                                    subtitle: (snapshot?.generationPowerW ?? 0) > 10 ? "Üretim Aktif" : "Beklemede",
                                    tintColor: .orange,
                                    isEmphasized: (snapshot?.generationPowerW ?? 0) > 10
                                )

                                EnergyCard(
                                    title: "Ev Tüketimi",
                                    icon: "house.fill",
                                    valueText: Formatters.power(snapshot?.consumptionPowerW),
                                    subtitle: "Anlık Tüketim",
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
                                    icon: isCharging ? "arrow.down.forward" : (isDischarging ? "arrow.up.forward" : "pause.fill"),
                                    valueText: Formatters.power(abs(effectiveBatt)),
                                    subtitle: isCharging ? "Şarj Ediliyor" : (isDischarging ? "Deşarj Oluyor" : "Durağan (0 W)"),
                                    tintColor: isCharging ? .green : (isDischarging ? .orange : .secondary)
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // System Info / Footer bar
                    if let snapshot = appState.snapshot {
                        HStack {
                            Text("Santral ID: \(snapshot.stationId)")
                            Text("·")
                            Text("Son Başarılı Alım: \(Formatters.time(Date(timeIntervalSince1970: Double(snapshot.fetchedAtEpochMs) / 1000.0)))")
                            Spacer()
                            Text("Otomatik Yenileme: Her \(Int(appState.refreshInterval / 60)) dakikada bir")
                        }
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                    }
                }
                .padding(24)
            }
        }
    }
}
