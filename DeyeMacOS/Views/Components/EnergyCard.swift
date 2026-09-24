import SwiftUI

public struct EnergyCard: View {
    public let title: String
    public let icon: String
    public let valueText: String
    public let subtitle: String?
    public let tintColor: Color
    public var isEmphasized: Bool = false

    public init(
        title: String,
        icon: String,
        valueText: String,
        subtitle: String? = nil,
        tintColor: Color,
        isEmphasized: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.valueText = valueText
        self.subtitle = subtitle
        self.tintColor = tintColor
        self.isEmphasized = isEmphasized
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tintColor)
                    .frame(width: 28, height: 28)
                    .background(tintColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(valueText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(tintColor)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isEmphasized ? tintColor.opacity(0.4) : Color.primary.opacity(0.06), lineWidth: 1)
                }
        }
    }
}
