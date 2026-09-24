import Foundation
import CryptoKit

public enum CryptoHelper {
    /// Computes lowercase hex-encoded SHA-256 hash of the UTF-8 input string.
    /// Exactly matches Deye Cloud API requirements and Sha256.hexOfUtf8 in Android.
    public static func sha256Hex(_ string: String) -> String {
        let inputData = Data(string.utf8)
        let digest = SHA256.hash(data: inputData)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
