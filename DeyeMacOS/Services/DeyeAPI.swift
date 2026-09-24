import Foundation

public enum DeyeAPIError: LocalizedError {
    case invalidCredentials(String)
    case unauthorized
    case serverError(String)
    case invalidResponse
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials(let msg):
            return "Kimlik doğrulama hatası: \(msg)"
        case .unauthorized:
            return "Oturum süresi doldu (401 Unauthorized)"
        case .serverError(let msg):
            return "Deye Sunucu Hatası: \(msg)"
        case .invalidResponse:
            return "Sunucudan geçersiz veri alındı"
        case .networkError(let err):
            return "Ağ hatası: \(err.localizedDescription)"
        }
    }
}

public actor DeyeAPI {
    public static let shared = DeyeAPI()

    private var baseURL: URL = DeyeDataCenter.europe.resolvedURL ?? URL(string: "https://eu1-developer.deyecloud.com/v1.0/")!
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 25.0
        config.timeoutIntervalForResource = 30.0
        self.session = URLSession(configuration: config)
    }

    /// Sets the active data center for API calls
    public func setDataCenter(_ dataCenter: DeyeDataCenter) {
        if let url = dataCenter.resolvedURL {
            self.baseURL = url
        }
    }

    /// Sets the base URL directly
    public func setBaseURL(_ url: URL) {
        self.baseURL = url
    }

    /// Returns the current active base URL
    public func currentBaseURL() -> URL {
        return self.baseURL
    }

    /// Obtains an access token from Deye Cloud API, optionally targeting a specific base URL
    public func fetchToken(
        appId: String,
        appSecret: String,
        emailOrUsername: String,
        rawPassword: String,
        targetBaseURL: URL? = nil
    ) async throws -> String {
        let effectiveBaseURL = targetBaseURL ?? self.baseURL
        guard var components = URLComponents(url: effectiveBaseURL.appendingPathComponent("account/token"), resolvingAgainstBaseURL: true) else {
            throw DeyeAPIError.invalidResponse
        }
        components.queryItems = [
            URLQueryItem(name: "appId", value: appId)
        ]

        guard let url = components.url else {
            throw DeyeAPIError.invalidResponse
        }

        let trimmedLogin = emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let isEmail = trimmedLogin.contains("@")
        let hashedPassword = CryptoHelper.sha256Hex(rawPassword)

        let requestBody = TokenRequest(
            appSecret: appSecret,
            email: isEmail ? trimmedLogin : nil,
            username: isEmail ? nil : trimmedLogin,
            password: hashedPassword
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(requestBody)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DeyeAPIError.invalidResponse
            }

            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

            if httpResponse.statusCode == 401 {
                throw DeyeAPIError.unauthorized
            }

            guard httpResponse.statusCode == 200,
                  tokenResponse.success == true,
                  let token = tokenResponse.accessToken,
                  !token.isEmpty else {
                let msg = tokenResponse.msg ?? "HTTP \(httpResponse.statusCode)"
                throw DeyeAPIError.invalidCredentials(msg)
            }

            let cleanToken = token.hasPrefix("Bearer ") ? String(token.dropFirst(7)).trimmingCharacters(in: .whitespaces) : token
            self.baseURL = effectiveBaseURL
            return cleanToken
        } catch let err as DeyeAPIError {
            throw err
        } catch {
            throw DeyeAPIError.networkError(error)
        }
    }

    /// Fetches the list of stations associated with the user account
    public func listStations(token: String) async throws -> [StationItem] {
        let url = baseURL.appendingPathComponent("station/list")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let requestBody = StationListRequest(page: 1, size: 50)
        request.httpBody = try JSONEncoder().encode(requestBody)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DeyeAPIError.invalidResponse
            }

            if httpResponse.statusCode == 401 {
                throw DeyeAPIError.unauthorized
            }

            let listResponse = try JSONDecoder().decode(StationListResponse.self, from: data)
            if listResponse.success == false {
                throw DeyeAPIError.serverError(listResponse.msg ?? "İstasyon listesi alınamadı")
            }

            return listResponse.stationList ?? []
        } catch let err as DeyeAPIError {
            throw err
        } catch {
            throw DeyeAPIError.networkError(error)
        }
    }

    /// Fetches real-time telemetry metrics for a given station ID
    public func fetchStationLatest(token: String, stationId: Int64) async throws -> StationLatestResponse {
        let url = baseURL.appendingPathComponent("station/latest")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let requestBody = StationLatestRequest(stationId: stationId)
        request.httpBody = try JSONEncoder().encode(requestBody)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DeyeAPIError.invalidResponse
            }

            if httpResponse.statusCode == 401 {
                throw DeyeAPIError.unauthorized
            }

            let latestResponse = try JSONDecoder().decode(StationLatestResponse.self, from: data)
            if latestResponse.success == false {
                throw DeyeAPIError.serverError(latestResponse.msg ?? "Anlık veri alınamadı")
            }

            return latestResponse
        } catch let err as DeyeAPIError {
            throw err
        } catch {
            throw DeyeAPIError.networkError(error)
        }
    }

    /// Normalizes Deye epoch timestamps which may come as floating point seconds
    public static func normalizeEpoch(_ raw: Double?) -> Int64? {
        guard let raw = raw, raw > 0 else { return nil }
        let asLong = Int64(raw)
        // If it's less than 10 billion, it's in seconds -> convert to milliseconds
        return asLong < 10_000_000_000 ? asLong * 1000 : asLong
    }
}
