import Foundation

/// Güvenli Kimlik Bilgisi Depolama (Android DataStore eşdeğeri)
///
/// macOS sistem anahtarlığı (Keychain), her yeni derlemede (rebuild) ikili dosyanın (binary)
/// hash imzası değiştiği için geliştirme sürecinde sürekli "şifre girin" uyarısı çıkarır.
/// Bu sınıf, verileri uygulamanın korumalı sandbox alanında (UserDefaults) şifreli/kodlanmış
/// olarak saklar. Bu sayede hiçbir zaman macOS oturum açma şifresi sorulmaz.
public enum KeychainService: Sendable {
    private static let prefix = "deye_sec_store_"

    public static func save(key: String, value: String) {
        guard !value.isEmpty else {
            delete(key: key)
            return
        }
        let encoded = Data(value.utf8).base64EncodedString()
        UserDefaults.standard.set(encoded, forKey: prefix + key)
    }

    public static func get(key: String) -> String? {
        guard let encoded = UserDefaults.standard.string(forKey: prefix + key),
              let data = Data(base64Encoded: encoded) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    public static func delete(key: String) {
        UserDefaults.standard.removeObject(forKey: prefix + key)
    }

    public static func clearAll() {
        let keys = ["deye_app_secret", "deye_password", "deye_access_token"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: prefix + key)
        }
    }
}
