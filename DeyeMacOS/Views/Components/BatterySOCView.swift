import SwiftUI

public struct BatterySOCView: View {
    public let socPercent: Double?
    public let powerW: Double?
    public let isCharging: Bool
    public let isDischarging: Bool

    public init(socPercent: Double?, powerW: Double?, isCharging: Bool, isDischarging: Bool) {
        self.socPercent = socPercent
        self.powerW = powerW
        self.isCharging = isCharging
        self.isDischarging = isDischarging
    }

    private var percentageValue: Double {
        socPercent ?? 0.0
    }

    private var batteryColor: Color {
        if percentageValue > 50 {
            return Color.green
        } else if percentageValue > 20 {
            return Color.orange
        } else {
            return Color.red
        }
    }

    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: isCharging ? "battery.100percent.bolt" : "battery.75percent")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(batteryColor)

                    Text("Batarya Doluluk Oranı")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    if isCharging {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.down.forward")
                                .font(.caption2)
                            Text("Şarj \(Formatters.power(powerW, absolute: true))")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Color.green)
                    } else if isDischarging {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.forward")
                                .font(.caption2)
                            Text("Deşarj \(Formatters.power(powerW, absolute: true))")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Color.orange)
                    }

                    Text(Formatters.percentage(socPercent))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }

            // Progress bar
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [batteryColor.opacity(0.8), batteryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(proxy.size.width * CGFloat(percentageValue / 100.0), proxy.size.width)), height: 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentageValue)
                }
            }
            .frame(height: 10)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                }
        }
    }
}
