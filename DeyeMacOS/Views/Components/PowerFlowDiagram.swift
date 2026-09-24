import SwiftUI

public struct PowerFlowDiagram: View {
    public let snapshot: StationSnapshot?
    public var gridThreshold: Double
    public var batteryThreshold: Double

    public init(snapshot: StationSnapshot?, gridThreshold: Double = 150.0, batteryThreshold: Double = 200.0) {
        self.snapshot = snapshot
        self.gridThreshold = gridThreshold
        self.batteryThreshold = batteryThreshold
    }

    private var pvPower: Double { snapshot?.generationPowerW ?? 0 }
    private var homePower: Double { snapshot?.consumptionPowerW ?? 0 }
    private var effectiveGrid: Double { snapshot?.effectiveGridPower(threshold: gridThreshold) ?? 0 }
    private var effectiveBatt: Double { snapshot?.effectiveBatteryPower(threshold: batteryThreshold) ?? 0 }
    private var isCharging: Bool { snapshot?.isCharging(threshold: batteryThreshold) ?? false }
    private var isDischarging: Bool { snapshot?.isDischarging(threshold: batteryThreshold) ?? false }
    private var soc: Double { snapshot?.batterySocPercent ?? 0 }

    public var body: some View {
        VStack(spacing: 16) {
            // Top: Solar PV
            flowNode(
                title: "Güneş (PV)",
                value: Formatters.power(pvPower),
                icon: "sun.max.fill",
                color: .orange,
                isActive: pvPower > 10
            )

            // Connection Arrow down from PV to Inverter
            flowArrow(direction: .down, isActive: pvPower > 10, color: .orange)

            // Middle row: Grid <--> Inverter <--> Home
            HStack(spacing: 20) {
                // Left: Grid
                flowNode(
                    title: "Şebeke",
                    value: Formatters.power(abs(effectiveGrid)),
                    icon: "bolt.fill",
                    color: effectiveGrid >= gridThreshold ? .green : (effectiveGrid <= -gridThreshold ? .blue : .secondary),
                    statusText: effectiveGrid >= gridThreshold ? "Satış" : (effectiveGrid <= -gridThreshold ? "Alış" : "Dengeli (0 W)"),
                    isActive: abs(effectiveGrid) >= gridThreshold
                )

                // Arrow Grid <-> Inverter
                flowArrow(
                    direction: effectiveGrid >= gridThreshold ? .left : (effectiveGrid <= -gridThreshold ? .right : .none),
                    isActive: abs(effectiveGrid) >= gridThreshold,
                    color: effectiveGrid >= gridThreshold ? .green : .blue
                )

                // Center: Deye Inverter Hub
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .frame(width: 58, height: 58)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .overlay {
                                Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1.5)
                            }

                        Image(systemName: "powerplug.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.accentColor)
                    }

                    Text("İnvertör")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }

                // Arrow Inverter -> Home
                flowArrow(direction: .right, isActive: homePower > 10, color: .purple)

                // Right: Home
                flowNode(
                    title: "Ev",
                    value: Formatters.power(homePower),
                    icon: "house.fill",
                    color: .purple,
                    isActive: homePower > 10
                )
            }

            // Connection Arrow Inverter <-> Battery
            flowArrow(
                direction: isCharging ? .down : (isDischarging ? .up : .none),
                isActive: isCharging || isDischarging,
                color: isCharging ? .green : .orange
            )

            // Bottom: Battery
            flowNode(
                title: "Batarya",
                value: (isCharging || isDischarging) ? "\(Formatters.power(abs(effectiveBatt))) (\(Formatters.percentage(soc)))" : "Durağan (\(Formatters.percentage(soc)))",
                icon: isCharging ? "battery.100percent.bolt" : "battery.75percent",
                color: soc > 50 ? .green : (soc > 20 ? .orange : .red),
                statusText: isCharging ? "Şarj" : (isDischarging ? "Deşarj" : "Beklemede"),
                isActive: isCharging || isDischarging
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }
        }
    }

    private func flowNode(
        title: String,
        value: String,
        icon: String,
        color: Color,
        statusText: String? = nil,
        isActive: Bool
    ) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(isActive ? 0.2 : 0.08))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .stroke(color.opacity(isActive ? 0.8 : 0.2), lineWidth: 1.5)
                    }

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isActive ? color : .secondary)
            }

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            if let st = statusText {
                Text(st)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .frame(minWidth: 100)
    }

    private enum ArrowDir { case down, up, right, left, none }

    private func flowArrow(direction: ArrowDir, isActive: Bool, color: Color) -> some View {
        Group {
            switch direction {
            case .down:
                Image(systemName: "arrow.down")
            case .up:
                Image(systemName: "arrow.up")
            case .right:
                Image(systemName: "arrow.right")
            case .left:
                Image(systemName: "arrow.left")
            case .none:
                Image(systemName: "circle.fill")
                    .font(.system(size: 4))
            }
        }
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(isActive ? color : Color.secondary.opacity(0.3))
        .opacity(isActive ? 1.0 : 0.4)
    }
}
