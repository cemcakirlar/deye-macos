import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    // MARK: - Published Properties

    @Published public var isLoggedIn: Bool = false
    @Published public var credentials: Credentials = Credentials(appId: "", appSecret: "", emailOrUsername: "", password: "")
    @Published public var stations: [StationItem] = []
    @Published public var selectedStationId: Int64? = nil
    @Published public var selectedStationName: String = ""
    @Published public var snapshot: StationSnapshot? = nil
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var needsStationSelection: Bool = false
    @Published public var refreshInterval: TimeInterval = 300 // 5 minutes default
    @Published public var menuBarDisplayMode: MenuBarDisplayMode = .solarAndBattery

    // MARK: - Private State

    private var cachedToken: String?
    private var refreshTimer: AnyCancellable?
    private let userDefaults = UserDefaults.standard

    // Keys for UserDefaults
    private enum Keys {
        static let appId = "deye_app_id"
        static let emailOrUsername = "deye_email_or_username"
        static let stationId = "deye_station_id"
        static let stationName = "deye_station_name"
        static let refreshInterval = "deye_refresh_interval"
        static let menuBarDisplayMode = "deye_menubar_display_mode"
        static let cachedSnapshot = "deye_cached_snapshot"
    }

    private enum KeychainKeys {
        static let appSecret = "deye_app_secret"
        static let password = "deye_password"
        static let accessToken = "deye_access_token"
    }

    // MARK: - Initializer

    public init() {
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
        let savedAppId = userDefaults.string(forKey: Keys.appId) ?? ""
        let savedEmail = userDefaults.string(forKey: Keys.emailOrUsername) ?? ""
        let savedSecret = KeychainService.get(key: KeychainKeys.appSecret) ?? ""
        let savedPassword = KeychainService.get(key: KeychainKeys.password) ?? ""
        self.cachedToken = KeychainService.get(key: KeychainKeys.accessToken)

        self.credentials = Credentials(
            appId: savedAppId,
            appSecret: savedSecret,
            emailOrUsername: savedEmail,
            password: savedPassword
        )

        let stationId = userDefaults.object(forKey: Keys.stationId) as? Int64
        self.selectedStationId = stationId
        self.selectedStationName = userDefaults.string(forKey: Keys.stationName) ?? ""

        let interval = userDefaults.double(forKey: Keys.refreshInterval)
        if interval >= 30 {
            self.refreshInterval = interval
        }

        if let modeRaw = userDefaults.string(forKey: Keys.menuBarDisplayMode),
           let mode = MenuBarDisplayMode(rawValue: modeRaw) {
            self.menuBarDisplayMode = mode
        }

        // Restore cached snapshot for instantaneous UI display
        if let data = userDefaults.data(forKey: Keys.cachedSnapshot),
           let cached = try? JSONDecoder().decode(StationSnapshot.self, from: data) {
            self.snapshot = cached
        }

        self.isLoggedIn = credentials.isValid
    }

    public func saveCredentials(_ newCredentials: Credentials) {
        self.credentials = newCredentials
        userDefaults.set(newCredentials.appId, forKey: Keys.appId)
        userDefaults.set(newCredentials.emailOrUsername, forKey: Keys.emailOrUsername)
        KeychainService.save(key: KeychainKeys.appSecret, value: newCredentials.appSecret)
        KeychainService.save(key: KeychainKeys.password, value: newCredentials.password)
        self.isLoggedIn = newCredentials.isValid
    }

    public func setRefreshInterval(_ interval: TimeInterval) {
        self.refreshInterval = interval
        userDefaults.set(interval, forKey: Keys.refreshInterval)
        setupTimer()
    }

    public func setMenuBarDisplayMode(_ mode: MenuBarDisplayMode) {
        self.menuBarDisplayMode = mode
        userDefaults.set(mode.rawValue, forKey: Keys.menuBarDisplayMode)
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

    public func login() async {
        guard credentials.isValid else {
            self.errorMessage = "Lütfen tüm kimlik bilgilerini eksiksiz doldurun."
            return
        }

        self.isLoading = true
        self.errorMessage = nil

        do {
            let token = try await DeyeAPI.shared.fetchToken(
                appId: credentials.appId,
                appSecret: credentials.appSecret,
                emailOrUsername: credentials.emailOrUsername,
                rawPassword: credentials.password
            )
            self.cachedToken = token
            KeychainService.save(key: KeychainKeys.accessToken, value: token)
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
        self.selectedStationId = nil
        self.selectedStationName = ""
        self.errorMessage = nil

        KeychainService.clearAll()
        userDefaults.removeObject(forKey: Keys.appId)
        userDefaults.removeObject(forKey: Keys.emailOrUsername)
        userDefaults.removeObject(forKey: Keys.stationId)
        userDefaults.removeObject(forKey: Keys.stationName)
        userDefaults.removeObject(forKey: Keys.cachedSnapshot)

        self.credentials = Credentials(appId: "", appSecret: "", emailOrUsername: "", password: "")
    }

    public func selectStation(_ station: StationItem) async {
        guard let id = station.resolvedId else { return }
        self.selectedStationId = id
        self.selectedStationName = station.displayName
        userDefaults.set(id, forKey: Keys.stationId)
        userDefaults.set(station.displayName, forKey: Keys.stationName)
        self.needsStationSelection = false

        await refresh()
    }

    public func refresh() async {
        guard isLoggedIn else { return }
        self.isLoading = true
        self.errorMessage = nil

        do {
            let token = try await getOrRefreshToken()

            // Check station list if no station selected
            if selectedStationId == nil {
                let fetchedStations = try await DeyeAPI.shared.listStations(token: token)
                self.stations = fetchedStations

                if fetchedStations.isEmpty {
                    throw DeyeAPIError.serverError("Hesaba bağlı istasyon bulunamadı")
                } else if fetchedStations.count == 1, let first = fetchedStations.first, let firstId = first.resolvedId {
                    self.selectedStationId = firstId
                    self.selectedStationName = first.displayName
                    userDefaults.set(firstId, forKey: Keys.stationId)
                    userDefaults.set(first.displayName, forKey: Keys.stationName)
                } else {
                    self.needsStationSelection = true
                    self.isLoading = false
                    return
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
            rawPassword: credentials.password
        )
        self.cachedToken = token
        KeychainService.save(key: KeychainKeys.accessToken, value: token)
        return token
    }
}
