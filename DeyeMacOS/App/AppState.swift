import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    // MARK: - Published Properties

    @Published public var isLoggedIn: Bool = false
    @Published public var credentials: Credentials = Credentials(appId: "", appSecret: "", emailOrUsername: "", password: "")
    @Published public var stations: [StationItem] = []
    @Published public var snapshot: StationSnapshot? = nil
    @Published public var stationSnapshots: [Int64: StationSnapshot] = [:]
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var needsStationSelection: Bool = false
    @Published public var config: AppConfig

    public var selectedStationId: Int64? {
        get { config.selectedStationId }
        set {
            config.selectedStationId = newValue
            config.save()
        }
    }

    public var selectedStationName: String {
        get { config.selectedStationName }
        set {
            config.selectedStationName = newValue
            config.save()
        }
    }

    public var refreshInterval: TimeInterval {
        get { config.refreshInterval }
        set { setRefreshInterval(newValue) }
    }

    public var menuBarDisplayMode: MenuBarDisplayMode {
        get { config.menuBarDisplayMode }
        set { setMenuBarDisplayMode(newValue) }
    }

    public var gridImportThresholdW: Double {
        get { config.gridImportThresholdW }
        set { setGridImportThreshold(newValue) }
    }

    public var gridExportThresholdW: Double {
        get { config.gridExportThresholdW }
        set { setGridExportThreshold(newValue) }
    }

    public var batteryChargeThresholdW: Double {
        get { config.batteryChargeThresholdW }
        set { setBatteryChargeThreshold(newValue) }
    }

    public var batteryDischargeThresholdW: Double {
        get { config.batteryDischargeThresholdW }
        set { setBatteryDischargeThreshold(newValue) }
    }

    public var selectedDataCenter: DeyeDataCenter {
        get { config.selectedDataCenter }
        set { setDataCenter(newValue) }
    }

    public var showMainWindowOnLaunch: Bool {
        get { config.showMainWindowOnLaunch }
        set { setShowMainWindowOnLaunch(newValue) }
    }

    // MARK: - Private State

    private var cachedToken: String?
    private var refreshTimer: AnyCancellable?
    private let userDefaults = UserDefaults.standard

    // Keys for UserDefaults
    private enum Keys {
        static let cachedSnapshot = "deye_cached_snapshot"
        static let cachedStations = "deye_cached_stations"
    }

    private enum CredentialKeys {
        static let appSecret = "app_secret"
        static let password = "password"
        static let accessToken = "access_token"
    }

    // MARK: - Initializer

    public init() {
        config = AppConfig.load()
        loadStoredConfiguration()
        setupTimer()

        if isLoggedIn {
            Task {
                await refresh()
            }
        }
    }

    // MARK: - Persistence & Setup

    private func loadStoredConfiguration() {
        let savedSecret = CredentialStore.get(key: CredentialKeys.appSecret) ?? ""
        let savedPassword = CredentialStore.get(key: CredentialKeys.password) ?? ""
        self.cachedToken = CredentialStore.get(key: CredentialKeys.accessToken)

        self.credentials = Credentials(
            appId: config.appId,
            appSecret: savedSecret,
            emailOrUsername: config.emailOrUsername,
            password: savedPassword
        )

        if let data = userDefaults.data(forKey: Keys.cachedStations),
           let cachedStations = try? JSONDecoder().decode([StationItem].self, from: data) {
            self.stations = cachedStations
        }

        if let data = userDefaults.data(forKey: Keys.cachedSnapshot),
           let cached = try? JSONDecoder().decode(StationSnapshot.self, from: data) {
            self.snapshot = cached
            if let id = selectedStationId {
                self.stationSnapshots[id] = cached
            }
        }

        let center = config.selectedDataCenter
        Task {
            await DeyeAPI.shared.setDataCenter(center)
        }

        self.isLoggedIn = credentials.isValid
    }

    public func saveCredentials(_ newCredentials: Credentials) {
        self.credentials = newCredentials
        config.appId = newCredentials.appId
        config.emailOrUsername = newCredentials.emailOrUsername
        config.save()
        CredentialStore.save(key: CredentialKeys.appSecret, value: newCredentials.appSecret)
        CredentialStore.save(key: CredentialKeys.password, value: newCredentials.password)
        self.isLoggedIn = newCredentials.isValid
    }

    public func setRefreshInterval(_ interval: TimeInterval) {
        config.refreshInterval = interval
        config.save()
        setupTimer()
    }

    public func setMenuBarDisplayMode(_ mode: MenuBarDisplayMode) {
        config.menuBarDisplayMode = mode
        config.save()
    }

    public func setGridImportThreshold(_ value: Double) {
        config.gridImportThresholdW = max(0, value)
        config.save()
    }

    public func setGridExportThreshold(_ value: Double) {
        config.gridExportThresholdW = max(0, value)
        config.save()
    }

    public func setBatteryChargeThreshold(_ value: Double) {
        config.batteryChargeThresholdW = max(0, value)
        config.save()
    }

    public func setBatteryDischargeThreshold(_ value: Double) {
        config.batteryDischargeThresholdW = max(0, value)
        config.save()
    }

    public func setDataCenter(_ dataCenter: DeyeDataCenter) {
        config.selectedDataCenter = dataCenter
        config.save()
        Task {
            await DeyeAPI.shared.setDataCenter(dataCenter)
        }
    }

    public func setShowMainWindowOnLaunch(_ value: Bool) {
        config.showMainWindowOnLaunch = value
        config.save()
    }

    private func setupTimer() {
        refreshTimer?.cancel()
        refreshTimer = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isLoggedIn, !self.isLoading else { return }
                Task {
                    await self.refresh()
                }
            }
    }

    // MARK: - Actions

    public func login(dataCenter: DeyeDataCenter? = nil) async {
        guard credentials.isValid else {
            self.errorMessage = "Lütfen tüm kimlik bilgilerini eksiksiz doldurun."
            return
        }

        let targetCenter = dataCenter ?? self.selectedDataCenter

        self.isLoading = true
        self.errorMessage = nil

        do {
            let token = try await DeyeAPI.shared.fetchToken(
                appId: credentials.appId,
                appSecret: credentials.appSecret,
                emailOrUsername: credentials.emailOrUsername,
                rawPassword: credentials.password,
                targetBaseURL: targetCenter.resolvedURL
            )
            self.setDataCenter(targetCenter)
            self.cachedToken = token
            CredentialStore.save(key: CredentialKeys.accessToken, value: token)
            saveCredentials(credentials)
            self.isLoggedIn = true

            await refresh()
        } catch {
            self.errorMessage = error.localizedDescription
        }

        self.isLoading = false
    }

    public func logout() {
        self.isLoggedIn = false
        self.cachedToken = nil
        self.snapshot = nil
        self.stations = []
        self.stationSnapshots = [:]
        self.errorMessage = nil

        CredentialStore.clearAll()
        config.clearAccount()
        userDefaults.removeObject(forKey: Keys.cachedSnapshot)
        userDefaults.removeObject(forKey: Keys.cachedStations)

        self.credentials = Credentials(appId: "", appSecret: "", emailOrUsername: "", password: "")
    }

    public func selectStation(_ station: StationItem) async {
        guard let id = station.resolvedId else { return }
        config.selectedStationId = id
        config.selectedStationName = station.displayName
        config.save()
        self.needsStationSelection = false

        if let cached = stationSnapshots[id] {
            self.snapshot = cached
        }

        await refresh()
    }

    public func refresh() async {
        guard isLoggedIn else { return }
        self.isLoading = true
        self.errorMessage = nil

        do {
            let token = try await getOrRefreshToken()

            // Always fetch stations list so we know all available stations in account
            let fetchedStations = try await DeyeAPI.shared.listStations(token: token)
            self.stations = fetchedStations
            if let encoded = try? JSONEncoder().encode(fetchedStations) {
                userDefaults.set(encoded, forKey: Keys.cachedStations)
            }

            if fetchedStations.isEmpty {
                throw DeyeAPIError.serverError("Hesaba bağlı istasyon bulunamadı")
            }

            if selectedStationId == nil || !fetchedStations.contains(where: { $0.resolvedId == selectedStationId }) {
                if let first = fetchedStations.first, let firstId = first.resolvedId {
                    config.selectedStationId = firstId
                    config.selectedStationName = first.displayName
                    config.save()
                }
            }

            guard let stationId = selectedStationId else {
                self.needsStationSelection = true
                self.isLoading = false
                return
            }

            // Fetch station telemetry with automatic retry on 401
            let latest: StationLatestResponse
            do {
                latest = try await DeyeAPI.shared.fetchStationLatest(token: token, stationId: stationId)
            } catch DeyeAPIError.unauthorized {
                // Re-fetch token and retry once
                let freshToken = try await obtainFreshToken()
                latest = try await DeyeAPI.shared.fetchStationLatest(token: freshToken, stationId: stationId)
            }

            let normalizedLastUpdate = DeyeAPI.normalizeEpoch(latest.lastUpdateTime)
            let newSnapshot = StationSnapshot(
                stationId: stationId,
                stationName: selectedStationName.isEmpty ? "Deye" : selectedStationName,
                generationPowerW: latest.generationPower,
                consumptionPowerW: latest.consumptionPower,
                wirePowerW: latest.wirePower ?? latest.gridPower,
                batteryPowerW: latest.batteryPower,
                batterySocPercent: latest.batterySOC,
                chargePowerW: latest.chargePower,
                dischargePowerW: latest.dischargePower,
                lastUpdateEpochMs: normalizedLastUpdate,
                fetchedAtEpochMs: Int64(Date().timeIntervalSince1970 * 1000),
                errorMessage: nil
            )

            self.snapshot = newSnapshot
            self.stationSnapshots[stationId] = newSnapshot

            // Cache snapshot for offline or fast startup
            if let encoded = try? JSONEncoder().encode(newSnapshot) {
                userDefaults.set(encoded, forKey: Keys.cachedSnapshot)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }

        self.isLoading = false
    }

    private func getOrRefreshToken() async throws -> String {
        if let token = cachedToken, !token.isEmpty {
            return token
        }
        return try await obtainFreshToken()
    }

    private func obtainFreshToken() async throws -> String {
        let token = try await DeyeAPI.shared.fetchToken(
            appId: credentials.appId,
            appSecret: credentials.appSecret,
            emailOrUsername: credentials.emailOrUsername,
            rawPassword: credentials.password,
            targetBaseURL: selectedDataCenter.resolvedURL
        )
        self.cachedToken = token
        CredentialStore.save(key: CredentialKeys.accessToken, value: token)
        return token
    }
}
