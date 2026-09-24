import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header with title and close button
            HStack {
                Text("Ayarlar")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Kapat (Esc)")
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            TabView {
                // General Tab
                Form {
                    Section("Veri Yenileme") {
                        Picker("Otomatik Yenileme:", selection: Binding(
                            get: { appState.refreshInterval },
                            set: { appState.setRefreshInterval($0) }
                        )) {
                            Text("1 dakika").tag(TimeInterval(60))
                            Text("3 dakika").tag(TimeInterval(180))
                            Text("5 dakika (Varsayılan)").tag(TimeInterval(300))
                            Text("10 dakika").tag(TimeInterval(600))
                            Text("15 dakika").tag(TimeInterval(900))
                            Text("30 dakika").tag(TimeInterval(1800))
                        }

                        Text("Deye bulut sunucularından verinin periyodik olarak ne sıklıkla çekileceğini belirler.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section("Menü Çubuğu (Status Bar)") {
                        Picker("Görünüm Şekli:", selection: Binding(
                            get: { appState.menuBarDisplayMode },
                            set: { appState.setMenuBarDisplayMode($0) }
                        )) {
                            ForEach(MenuBarDisplayMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }

                        // Live Preview Box
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Canlı Menü Çubuğu Önizlemesi:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            HStack {
                                previewLabel(for: appState.menuBarDisplayMode)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                                    }

                                Spacer()
                            }
                        }
                        .padding(.top, 2)

                        Text("macOS üst menü çubuğunda gösterilecek özet metrikleri anında günceller.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section("Güç Eşik Değerleri (Tolerans / Deadband)") {
                        // Grid Threshold
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Şebeke Eşiği:", systemImage: "bolt.fill")
                                    .foregroundStyle(.blue)
                                Spacer()
                                Text("±\(Int(appState.gridPowerThresholdW)) W")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.accentColor)

                                Stepper("", value: Binding(
                                    get: { appState.gridPowerThresholdW },
                                    set: { appState.setGridPowerThreshold($0) }
                                ), in: 0...500, step: 25)
                                .labelsHidden()
                            }

                            HStack(spacing: 6) {
                                Text("Hızlı Seçim:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ForEach([50.0, 100.0, 150.0, 200.0, 300.0], id: \.self) { val in
                                    Button("\(Int(val)) W\(val == 150.0 ? " (Varsayılan)" : "")") {
                                        appState.setGridPowerThreshold(val)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                    .tint(appState.gridPowerThresholdW == val ? .accentColor : .secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)

                        Divider()

                        // Battery Threshold
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Batarya Eşiği:", systemImage: "battery.100percent.bolt")
                                    .foregroundStyle(.green)
                                Spacer()
                                Text("±\(Int(appState.batteryPowerThresholdW)) W")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.accentColor)

                                Stepper("", value: Binding(
                                    get: { appState.batteryPowerThresholdW },
                                    set: { appState.setBatteryPowerThreshold($0) }
                                ), in: 0...500, step: 25)
                                .labelsHidden()
                            }

                            HStack(spacing: 6) {
                                Text("Hızlı Seçim:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ForEach([50.0, 100.0, 150.0, 200.0, 300.0], id: \.self) { val in
                                    Button("\(Int(val)) W\(val == 200.0 ? " (Varsayılan)" : "")") {
                                        appState.setBatteryPowerThreshold(val)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                    .tint(appState.batteryPowerThresholdW == val ? .accentColor : .secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)

                        Text("Şebeke CT sensörleri (varsayılan ±150 W) ve batarya BMS sensörlerindeki (varsayılan ±200 W) küçük ölçüm sapmalarını sıfır kabul ederek durağan durumda sahte şarj ikonu veya akış oklarını filtreler.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .formStyle(.grouped)
                .tabItem {
                    Label("Genel", systemImage: "gear")
                }

                // Account Tab
                Form {
                    Section("Deye Cloud Hesabı") {
                        LabeledContent("E-posta / Kullanıcı:", value: appState.credentials.emailOrUsername.isEmpty ? "Girilmedi" : appState.credentials.emailOrUsername)
                        LabeledContent("App ID:", value: appState.credentials.appId.isEmpty ? "Girilmedi" : appState.credentials.appId)
                        LabeledContent("Aktif Santral:", value: appState.selectedStationName.isEmpty ? "Seçilmedi" : appState.selectedStationName)

                        Button("Hesaptan Çıkış Yap", role: .destructive) {
                            appState.logout()
                            dismiss()
                        }
                        .padding(.top, 8)
                    }
                }
                .formStyle(.grouped)
                .tabItem {
                    Label("Hesap", systemImage: "person.circle")
                }

                // About Tab
                VStack(spacing: 12) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)

                    Text("Deye Solar Monitor for macOS")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Sürüm 1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Deye solar inverter ve ev enerji depolama sistemleri için modern, yerel macOS takip uygulaması.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem {
                    Label("Hakkında", systemImage: "info.circle")
                }
            }
            .padding(.horizontal, 8)

            Divider()

            // Bottom Bar with prominent Close button
            HStack {
                Spacer()

                Button("Kapat") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction) // Esc shortcut
                .keyboardShortcut(.defaultAction) // Return/Enter shortcut
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 550, height: 690)
    }

    @ViewBuilder
    private func previewLabel(for mode: MenuBarDisplayMode) -> some View {
        let solar = Formatters.compactPower(appState.snapshot?.generationPowerW ?? 2450)
        let soc = Formatters.percentage(appState.snapshot?.batterySocPercent ?? 85)
        let home = Formatters.compactPower(appState.snapshot?.consumptionPowerW ?? 650)
        let gridThreshold = appState.gridPowerThresholdW
        let battThreshold = appState.batteryPowerThresholdW
        let effectiveGrid = appState.snapshot?.effectiveGridPower(threshold: gridThreshold) ?? 0
        let grid = Formatters.compactPower(abs(effectiveGrid))
        let isCharging = appState.snapshot?.isCharging(threshold: battThreshold) ?? false
        let battEmoji = isCharging ? "⚡️🔋" : "🔋"

        switch mode {
        case .solarAndBattery:
            Text("☀️ \(solar)  \(battEmoji) \(soc)")
        case .solarOnly:
            Text("☀️ \(solar)")
        case .fullSummary:
            let gridEmoji = effectiveGrid >= gridThreshold ? "⚡️↗" : (effectiveGrid <= -gridThreshold ? "⚡️↘" : "⚡️")
            Text("☀️ \(solar)  \(battEmoji) \(soc)  🏠 \(home)  \(gridEmoji) \(grid)")
        case .iconOnly:
            Text("☀️")
                .font(.system(size: 16))
        }
    }
}
