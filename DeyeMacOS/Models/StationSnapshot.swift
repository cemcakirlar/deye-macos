import Foundation

public struct StationSnapshot: Codable, Equatable, Sendable {
    public let stationId: Int64
    public let stationName: String
    public let generationPowerW: Double?
    public let consumptionPowerW: Double?
    public let wirePowerW: Double?
    public let batteryPowerW: Double?
    public let batterySocPercent: Double?
    public let chargePowerW: Double?
    public let dischargePowerW: Double?
    public let lastUpdateEpochMs: Int64?
    public let fetchedAtEpochMs: Int64
    public let errorMessage: String?

    public init(
        stationId: Int64,
        stationName: String,
        generationPowerW: Double?,
        consumptionPowerW: Double?,
        wirePowerW: Double?,
        batteryPowerW: Double?,
        batterySocPercent: Double?,
        chargePowerW: Double? = nil,
        dischargePowerW: Double? = nil,
        lastUpdateEpochMs: Int64?,
        fetchedAtEpochMs: Int64,
        errorMessage: String? = nil
    ) {
        self.stationId = stationId
        self.stationName = stationName
        self.generationPowerW = generationPowerW
        self.consumptionPowerW = consumptionPowerW
        self.wirePowerW = wirePowerW
        self.batteryPowerW = batteryPowerW
        self.batterySocPercent = batterySocPercent
        self.chargePowerW = chargePowerW
        self.dischargePowerW = dischargePowerW
        self.lastUpdateEpochMs = lastUpdateEpochMs
        self.fetchedAtEpochMs = fetchedAtEpochMs
        self.errorMessage = errorMessage
    }

    /// True if latest update is older than 15 minutes
    public var isStale: Bool {
        let referenceMs = lastUpdateEpochMs ?? fetchedAtEpochMs
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        return (nowMs - referenceMs) > (15 * 60 * 1000)
    }

    /// Date object of last telemetry update
    public var lastUpdateDate: Date {
        let ms = lastUpdateEpochMs ?? fetchedAtEpochMs
        return Date(timeIntervalSince1970: Double(ms) / 1000.0)
    }

    /// Battery state: Charging, Discharging, or Idle
    public var isCharging: Bool {
        if let charge = chargePowerW, charge > 10 { return true }
        if let batt = batteryPowerW, batt < -10 { return true }
        return false
    }

    public var isDischarging: Bool {
        if let discharge = dischargePowerW, discharge > 10 { return true }
        if let batt = batteryPowerW, batt > 10 { return true }
        return false
    }

    /// Grid state: Buying (Importing) or Selling (Exporting)
    public var isSellingToGrid: Bool {
        guard let wire = wirePowerW else { return false }
        return wire > 20
    }

    public var isBuyingFromGrid: Bool {
        guard let wire = wirePowerW else { return false }
        return wire < -20
    }
}
