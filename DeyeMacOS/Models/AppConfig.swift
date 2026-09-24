import Foundation

public struct AppConfig: Codable, Sendable, Equatable {
    public var appId: String = ""
    public var emailOrUsername: String = ""
    public var selectedStationId: Int64? = nil
    public var selectedStationName: String = ""
    public var selectedDataCenter: DeyeDataCenter = .europe
    public var refreshInterval: TimeInterval = 300
    public var menuBarDisplayMode: MenuBarDisplayMode = .solarAndBattery
    public var showMainWindowOnLaunch: Bool = false
    public var gridImportThresholdW: Double = 150.0
    public var gridExportThresholdW: Double = 150.0
    public var batteryChargeThresholdW: Double = 200.0
    public var batteryDischargeThresholdW: Double = 200.0

    public init() {}

    private enum Keys {
        static let appId = "deye_app_id"
        static let emailOrUsername = "deye_email_or_username"
        static let stationId = "deye_station_id"
        static let stationName = "deye_station_name"
        static let refreshInterval = "deye_refresh_interval"
        static let menuBarDisplayMode = "deye_menubar_display_mode"
        static let selectedDataCenter = "deye_selected_datacenter"
        static let gridImportThreshold = "deye_grid_import_threshold_w"
        static let gridExportThreshold = "deye_grid_export_threshold_w"
        static let batteryChargeThreshold = "deye_battery_charge_threshold_w"
        static let batteryDischargeThreshold = "deye_battery_discharge_threshold_w"
        static let gridPowerThreshold = "deye_grid_power_threshold_w"
        static let legacyPowerThreshold = "deye_power_threshold_w"
        static let batteryPowerThreshold = "deye_battery_power_threshold_w"
        static let showMainWindowOnLaunch = "deye_show_main_window_on_launch"
    }

    public static func load(defaults: UserDefaults = .standard) -> AppConfig {
        var config = AppConfig()
        config.appId = defaults.string(forKey: Keys.appId) ?? ""
        config.emailOrUsername = defaults.string(forKey: Keys.emailOrUsername) ?? ""
        config.selectedStationId = int64Value(forKey: Keys.stationId, defaults: defaults)
        config.selectedStationName = defaults.string(forKey: Keys.stationName) ?? ""

        let interval = defaults.double(forKey: Keys.refreshInterval)
        if interval >= 30 {
            config.refreshInterval = interval
        }

        if let modeRaw = defaults.string(forKey: Keys.menuBarDisplayMode),
           let mode = MenuBarDisplayMode(rawValue: modeRaw) {
            config.menuBarDisplayMode = mode
        }

        let legacyGrid = doubleValue(forKey: Keys.gridPowerThreshold, defaults: defaults)
            ?? doubleValue(forKey: Keys.legacyPowerThreshold, defaults: defaults)
        config.gridImportThresholdW = doubleValue(forKey: Keys.gridImportThreshold, defaults: defaults) ?? legacyGrid ?? 150.0
        config.gridExportThresholdW = doubleValue(forKey: Keys.gridExportThreshold, defaults: defaults) ?? legacyGrid ?? 150.0

        let legacyBattery = doubleValue(forKey: Keys.batteryPowerThreshold, defaults: defaults)
        config.batteryChargeThresholdW = doubleValue(forKey: Keys.batteryChargeThreshold, defaults: defaults) ?? legacyBattery ?? 200.0
        config.batteryDischargeThresholdW = doubleValue(forKey: Keys.batteryDischargeThreshold, defaults: defaults) ?? legacyBattery ?? 200.0

        config.showMainWindowOnLaunch = defaults.bool(forKey: Keys.showMainWindowOnLaunch)

        if let data = defaults.data(forKey: Keys.selectedDataCenter),
           let savedCenter = try? JSONDecoder().decode(DeyeDataCenter.self, from: data) {
            config.selectedDataCenter = savedCenter
        }

        return config
    }

    public func save(defaults: UserDefaults = .standard) {
        defaults.set(appId, forKey: Keys.appId)
        defaults.set(emailOrUsername, forKey: Keys.emailOrUsername)
        if let selectedStationId {
            defaults.set(selectedStationId, forKey: Keys.stationId)
        } else {
            defaults.removeObject(forKey: Keys.stationId)
        }
        defaults.set(selectedStationName, forKey: Keys.stationName)
        defaults.set(refreshInterval, forKey: Keys.refreshInterval)
        defaults.set(menuBarDisplayMode.rawValue, forKey: Keys.menuBarDisplayMode)
        defaults.set(showMainWindowOnLaunch, forKey: Keys.showMainWindowOnLaunch)
        defaults.set(gridImportThresholdW, forKey: Keys.gridImportThreshold)
        defaults.set(gridExportThresholdW, forKey: Keys.gridExportThreshold)
        defaults.set(batteryChargeThresholdW, forKey: Keys.batteryChargeThreshold)
        defaults.set(batteryDischargeThresholdW, forKey: Keys.batteryDischargeThreshold)
        if let encoded = try? JSONEncoder().encode(selectedDataCenter) {
            defaults.set(encoded, forKey: Keys.selectedDataCenter)
        }
    }

    public mutating func clearAccount(defaults: UserDefaults = .standard) {
        appId = ""
        emailOrUsername = ""
        selectedStationId = nil
        selectedStationName = ""
        defaults.removeObject(forKey: Keys.appId)
        defaults.removeObject(forKey: Keys.emailOrUsername)
        defaults.removeObject(forKey: Keys.stationId)
        defaults.removeObject(forKey: Keys.stationName)
    }

    private static func int64Value(forKey key: String, defaults: UserDefaults) -> Int64? {
        guard let object = defaults.object(forKey: key) else { return nil }
        return (object as? NSNumber)?.int64Value
    }

    private static func doubleValue(forKey key: String, defaults: UserDefaults) -> Double? {
        guard let object = defaults.object(forKey: key) else { return nil }
        return (object as? NSNumber)?.doubleValue
    }
}
