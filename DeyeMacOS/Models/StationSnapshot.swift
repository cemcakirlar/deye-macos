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

    // MARK: - Threshold / Deadband Aware Calculations

    /// Returns effective grid power respecting separate import (+) and export (-) deadband thresholds.
    /// If wirePower is between -exportThreshold and +importThreshold, returns 0.0 (balanced / idle).
    public func effectiveGridPower(importThreshold: Double = 150.0, exportThreshold: Double = 150.0) -> Double {
        guard let wire = wirePowerW else { return 0.0 }
        if wire >= importThreshold || wire <= -exportThreshold {
            return wire
        }
        return 0.0
    }

    /// Returns effective battery power respecting separate charge (-) and discharge (+) deadband thresholds.
    /// If batteryPower is between -chargeThreshold and +dischargeThreshold, returns 0.0 (idle / full).
    public func effectiveBatteryPower(chargeThreshold: Double = 200.0, dischargeThreshold: Double = 200.0) -> Double {
        guard let batt = batteryPowerW else { return 0.0 }
        if batt >= dischargeThreshold || batt <= -chargeThreshold {
            return batt
        }
        return 0.0
    }

    /// Battery state: Charging with threshold (default 200W)
    public func isCharging(threshold: Double = 200.0) -> Bool {
        if let charge = chargePowerW, charge >= threshold { return true }
        if let batt = batteryPowerW, batt <= -threshold { return true }
        return false
    }

    /// Battery state: Discharging with threshold (default 200W)
    public func isDischarging(threshold: Double = 200.0) -> Bool {
        if let discharge = dischargePowerW, discharge >= threshold { return true }
        if let batt = batteryPowerW, batt >= threshold { return true }
        return false
    }

    /// Grid state: Selling (Exporting) with threshold (default 150W)
    /// In Deye/Solarman API: negative wirePower indicates exporting (selling) to grid
    public func isSellingToGrid(threshold: Double = 150.0) -> Bool {
        guard let wire = wirePowerW else { return false }
        return wire <= -threshold
    }

    /// Grid state: Buying (Importing) with threshold (default 150W)
    /// In Deye/Solarman API: positive wirePower indicates importing (buying) from grid
    public func isBuyingFromGrid(threshold: Double = 150.0) -> Bool {
        guard let wire = wirePowerW else { return false }
        return wire >= threshold
    }

    // MARK: - Backward Compatible Defaults (using 150W grid and 200W battery defaults)

    public var isCharging: Bool { isCharging(threshold: 200.0) }
    public var isDischarging: Bool { isDischarging(threshold: 200.0) }
    public var isSellingToGrid: Bool { isSellingToGrid(threshold: 150.0) }
    public var isBuyingFromGrid: Bool { isBuyingFromGrid(threshold: 150.0) }
}
