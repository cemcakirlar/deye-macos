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
                        PowerFlowDiagram(snapshot: appState.snapshot)
                            .frame(maxWidth: .infinity)

                        VStack(spacing: 16) {
                            let snapshot = appState.snapshot

                            BatterySOCView(
                                socPercent: snapshot?.batterySocPercent,
                                powerW: snapshot?.batteryPowerW,
                                isCharging: snapshot?.isCharging ?? false,
                                isDischarging: snapshot?.isDischarging ?? false
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

                                let gridPower = snapshot?.wirePowerW ?? 0
                                EnergyCard(
                                    title: "Şebeke",
                                    icon: "bolt.fill",
                                    valueText: Formatters.power(abs(gridPower)),
                                    subtitle: gridPower > 20 ? "Şebekeye Satış" : (gridPower < -20 ? "Şebekeden Alış" : "Dengeli"),
                                    tintColor: gridPower > 0 ? .green : .blue
                                )

                                EnergyCard(
                                    title: "Batarya Gücü",
                                    icon: (snapshot?.isCharging ?? false) ? "arrow.down.forward" : "arrow.up.forward",
                                    valueText: Formatters.power(abs(snapshot?.batteryPowerW ?? 0)),
                                    subtitle: (snapshot?.isCharging ?? false) ? "Şarj Ediliyor" : ((snapshot?.isDischarging ?? false) ? "Deşarj Oluyor" : "Durağan"),
                                    tintColor: (snapshot?.isCharging ?? false) ? .green : .orange
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
