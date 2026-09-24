import Foundation

@MainActor
public enum Formatters {
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .medium
        df.dateStyle = .none
        return df
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let r = RelativeDateTimeFormatter()
        r.unitsStyle = .short
        return r
    }()

    /// Formats power in Watts or Kilowatts (e.g., "350 W" or "2.45 kW")
    public static func power(_ watts: Double?, absolute: Bool = false) -> String {
        guard let w = watts else { return "-- W" }
        let value = absolute ? abs(w) : w
        if abs(value) >= 1000.0 {
            return String(format: "%.2f kW", value / 1000.0)
        } else {
            return String(format: "%.0f W", value)
        }
    }

    /// Compact format for Menu Bar (e.g., "2.4 kW" or "350 W")
    public static func compactPower(_ watts: Double?, absolute: Bool = false) -> String {
        guard let w = watts else { return "--" }
        let value = absolute ? abs(w) : w
        if abs(value) >= 1000.0 {
            return String(format: "%.1f kW", value / 1000.0)
        } else {
            return String(format: "%.0f W", value)
        }
    }

    /// Formats battery percentage (e.g. "%85" or "85%")
    public static func percentage(_ value: Double?) -> String {
        guard let v = value else { return "--%" }
        return String(format: "%%%d", Int(v.rounded()))
    }

    /// Formats timestamp as clock time "14:23:05"
    public static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// Formats relative time "3 dk. önce"
    public static func relative(_ date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}
