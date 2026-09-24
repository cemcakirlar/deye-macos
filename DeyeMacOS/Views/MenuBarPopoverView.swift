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

                // Battery SOC Bar
                BatterySOCView(
                    socPercent: snapshot?.batterySocPercent,
                    powerW: snapshot?.batteryPowerW,
                    isCharging: snapshot?.isCharging ?? false,
                    isDischarging: snapshot?.isDischarging ?? false
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
                        appState.needsStationSelection = true
                        openMainWindow()
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
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
