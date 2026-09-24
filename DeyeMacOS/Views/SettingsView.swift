import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    public init(appState: AppState) {
        self.appState = appState
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Sürüm \(version) (\(build))"
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

                    Section("Başlangıç Davranışı") {
                        Toggle("Uygulama açıldığında ana pencereyi göster", isOn: Binding(
                            get: { appState.showMainWindowOnLaunch },
                            set: { appState.setShowMainWindowOnLaunch($0) }
                        ))

                        Text("Kapalıyken (varsayılan), uygulama ilk çalıştığında ana pencere gizli kalır ve doğrudan menü çubuğunda sessizce başlar. İhtiyaç duyduğunuzda menü çubuğundaki 'Ana Pencere' butonundan açabilirsiniz.")
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
                        thresholdRow(
                            title: "Şebekeden Alış Eşiği (+)",
                            icon: "bolt.fill",
                            color: .blue,
                            value: appState.gridImportThresholdW,
                            onChange: { appState.setGridImportThreshold($0) },
                            presets: [0.0, 50.0, 100.0, 150.0, 200.0, 300.0],
                            defaultPreset: 150.0,
                            description: "Şebekeden eve güç çekildiğinde (tüketim) bu değerin altı dengeli (0 W) sayılır."
                        )

                        Divider()

                        thresholdRow(
                            title: "Şebekeye Satış Eşiği (-)",
                            icon: "bolt.fill",
                            color: .green,
                            value: appState.gridExportThresholdW,
                            onChange: { appState.setGridExportThreshold($0) },
                            presets: [0.0, 50.0, 100.0, 150.0, 200.0, 300.0],
                            defaultPreset: 150.0,
                            description: "Şebekeye üretim fazlası enerji basıldığında bu değerin altı dengeli (0 W) sayılır."
                        )

                        Divider()

                        thresholdRow(
                            title: "Batarya Şarj Eşiği (-)",
                            icon: "battery.100percent.bolt",
                            color: .green,
                            value: appState.batteryChargeThresholdW,
                            onChange: { appState.setBatteryChargeThreshold($0) },
                            presets: [0.0, 50.0, 100.0, 150.0, 200.0, 300.0],
                            defaultPreset: 200.0,
                            description: "Batarya şarj edilirken bu gücün altındaki değerler durağan kabul edilir."
                        )

                        Divider()

                        thresholdRow(
                            title: "Batarya Çekiş / Deşarj Eşiği (+)",
                            icon: "arrow.up.forward",
                            color: .orange,
                            value: appState.batteryDischargeThresholdW,
                            onChange: { appState.setBatteryDischargeThreshold($0) },
                            presets: [0.0, 50.0, 100.0, 150.0, 200.0, 300.0],
                            defaultPreset: 200.0,
                            description: "Bataryadan eve anlık güç çekildiğinde bu gücün altı durağan kabul edilir."
                        )

                        Text("Şebeke CT pensleri ve batarya BMS sensörlerinin artı (+) ve eksi (-) yöndeki küçük ölçüm sapmalarını bağımsız filtreler. Belirlenen eşik altındaki değerler durağan / dengeli (0 W) gösterilir.")
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

                    Text(appVersionString)
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
        .frame(width: 550, height: 750)
    }

    @ViewBuilder
    private func thresholdRow(
        title: String,
        icon: String,
        color: Color,
        value: Double,
        onChange: @escaping (Double) -> Void,
        presets: [Double],
        defaultPreset: Double,
        description: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(color)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(value)) W")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)

                Stepper("", value: Binding(
                    get: { value },
                    set: { onChange($0) }
                ), in: 0...1000, step: 25)
                .labelsHidden()
            }

            Text(description)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Text("Hızlı:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ForEach(presets, id: \.self) { val in
                    Button("\(Int(val)) W\(val == defaultPreset ? " (Varsayılan)" : "")") {
                        onChange(val)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .tint(value == val ? .accentColor : .secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func previewLabel(for mode: MenuBarDisplayMode) -> some View {
        let solar = Formatters.compactPower(appState.snapshot?.generationPowerW ?? 2450)
        let soc = Formatters.percentage(appState.snapshot?.batterySocPercent ?? 85)
        let home = Formatters.compactPower(appState.snapshot?.consumptionPowerW ?? 650)
        let gridImportTh = appState.gridImportThresholdW
        let gridExportTh = appState.gridExportThresholdW
        let battChargeTh = appState.batteryChargeThresholdW

        let effectiveGrid = appState.snapshot?.effectiveGridPower(importThreshold: gridImportTh, exportThreshold: gridExportTh) ?? 0
        let grid = Formatters.compactPower(abs(effectiveGrid))
        let isCharging = appState.snapshot?.isCharging(threshold: battChargeTh) ?? false
        let battEmoji = isCharging ? "⚡️🔋" : "🔋"

        switch mode {
        case .solarAndBattery:
            Text("☀️ \(solar)  \(battEmoji) \(soc)")
        case .solarOnly:
            Text("☀️ \(solar)")
        case .fullSummary:
            let isSelling = effectiveGrid <= -gridExportTh
            let isBuying = effectiveGrid >= gridImportTh
            let gridEmoji = isSelling ? "⚡️↗" : (isBuying ? "⚡️↘" : "⚡️")
            Text("☀️ \(solar)  \(battEmoji) \(soc)  🏠 \(home)  \(gridEmoji) \(grid)")
        case .iconOnly:
            Text("☀️")
                .font(.system(size: 16))
        }
    }
}
