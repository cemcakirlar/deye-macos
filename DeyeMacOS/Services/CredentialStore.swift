import Foundation

/// Android'deki `deye_secure_prefs` (DataStore / SharedPreferences) yaklaşımının
/// macOS eşdeğeri. Kimlik ve oturum verilerini macOS uygulama sandbox'ında
/// `UserDefaults` üzerinde saklar.
///
/// Apple Keychain ve `SecAccess` kullanılmadığı için:
/// 1. Her derleme sonrasında macOS sistem şifresi istemez.
/// 2. 'SecAccessCreate' veya 'SecKeychain' gibi eski API uyarısı üretmez.
/// 3. Android'deki çalışma mantığıyla birebir aynı stabiliteyi sağlar.
public enum CredentialStore: Sendable {
    private static let keyPrefix = "deye_cred_"

    public static func save(key: String, value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            delete(key: key)
            return
        }
        UserDefaults.standard.set(trimmed, forKey: keyPrefix + key)
    }

    public static func get(key: String) -> String? {
        UserDefaults.standard.string(forKey: keyPrefix + key)
    }

    public static func delete(key: String) {
        UserDefaults.standard.removeObject(forKey: keyPrefix + key)
    }

    public static func clearAll() {
        let keys = ["app_id", "app_secret", "email", "password", "access_token"]
        for key in keys {
            delete(key: key)
        }
    }
}
