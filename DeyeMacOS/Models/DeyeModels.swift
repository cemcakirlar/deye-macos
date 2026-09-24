import Foundation

// MARK: - API DTO Models

public struct TokenRequest: Codable, Sendable {
    public let appSecret: String
    public let email: String?
    public let username: String?
    public let password: String // SHA256 hex string

    public init(appSecret: String, email: String? = nil, username: String? = nil, password: String) {
        self.appSecret = appSecret
        self.email = email
        self.username = username
        self.password = password
    }
}

public struct TokenResponse: Codable, Sendable {
    public let success: Bool?
    public let code: String?
    public let msg: String?
    public let accessToken: String?
    public let expiresIn: String?
    public let refreshToken: String?
}

public struct StationListRequest: Codable, Sendable {
    public let page: Int
    public let size: Int

    public init(page: Int = 1, size: Int = 50) {
        self.page = page
        self.size = size
    }
}

public struct StationListResponse: Codable, Sendable {
    public let success: Bool?
    public let code: String?
    public let msg: String?
    public let total: Int?
    public let stationList: [StationItem]?
}

public struct StationItem: Codable, Identifiable, Hashable, Sendable {
    public let id: Int64?
    public let stationId: Int64?
    public let name: String?

    public var resolvedId: Int64? {
        stationId ?? id
    }

    public var displayName: String {
        name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? name! : "Santral #\(resolvedId ?? 0)"
    }
}

public struct StationLatestRequest: Codable, Sendable {
    public let stationId: Int64

    public init(stationId: Int64) {
        self.stationId = stationId
    }
}

public struct StationLatestResponse: Codable, Sendable {
    public let success: Bool?
    public let code: String?
    public let msg: String?
    public let generationPower: Double?
    public let consumptionPower: Double?
    public let wirePower: Double?
    public let gridPower: Double?
    public let batteryPower: Double?
    public let batterySOC: Double?
    public let chargePower: Double?
    public let dischargePower: Double?
    public let lastUpdateTime: Double?

    enum CodingKeys: String, CodingKey {
        case success, code, msg
        case generationPower, consumptionPower, wirePower, gridPower, batteryPower
        case batterySOC
        case chargePower, dischargePower, lastUpdateTime
    }
}

// MARK: - Credentials

public struct Credentials: Codable, Equatable, Sendable {
    public var appId: String
    public var appSecret: String
    public var emailOrUsername: String
    public var password: String

    public init(appId: String, appSecret: String, emailOrUsername: String, password: String) {
        self.appId = appId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.appSecret = appSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        self.emailOrUsername = emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        self.password = password
    }

    public var isValid: Bool {
        !appId.isEmpty && !appSecret.isEmpty && !emailOrUsername.isEmpty && !password.isEmpty
    }
}

// MARK: - Menu Bar Display Modes

public enum MenuBarDisplayMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case solarAndBattery = "solar_and_battery"
    case solarOnly = "solar_only"
    case fullSummary = "full_summary"
    case iconOnly = "icon_only"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .solarAndBattery:
            return "Güneş ve Batarya (☀️ + 🔋)"
        case .solarOnly:
            return "Sadece Güneş (☀️)"
        case .fullSummary:
            return "Tam Özet (☀️ + 🔋 + 🏠 + ⚡️)"
        case .iconOnly:
            return "Sadece İkon"
        }
    }
}

// MARK: - Data Centers

public struct DeyeDataCenter: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var name: String
    public var apiURL: String
    public var isCustom: Bool

    public init(id: String, name: String, apiURL: String, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.apiURL = apiURL.hasSuffix("/") ? apiURL : apiURL + "/"
        self.isCustom = isCustom
    }

    /// Resolved URL object
    public var resolvedURL: URL? {
        URL(string: apiURL)
    }

    /// Official known Deye Cloud data centers
    public static let europe = DeyeDataCenter(
        id: "eu",
        name: "Avrupa, Türkiye ve Afrika (eu1)",
        apiURL: "https://eu1-developer.deyecloud.com/v1.0/"
    )

    public static let americas = DeyeDataCenter(
        id: "am",
        name: "Kuzey ve Güney Amerika (us1)",
        apiURL: "https://us1-developer.deyecloud.com/v1.0/"
    )

    public static let india = DeyeDataCenter(
        id: "india",
        name: "Hindistan (india)",
        apiURL: "https://india-developer.deyecloud.com/v1.0/"
    )

    public static let custom = DeyeDataCenter(
        id: "custom",
        name: "Özel / Yeni Veri Merkezi (Custom URL)",
        apiURL: "https://",
        isCustom: true
    )

    public static let defaults: [DeyeDataCenter] = [
        .europe,
        .americas,
        .india,
        .custom
    ]
}
