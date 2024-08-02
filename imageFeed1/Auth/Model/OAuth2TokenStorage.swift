

import Foundation

final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()

    private let keychainService = KeychainService.shared
    private let tokenKey = "OAuth2Token"

    private init() {}

    var token: String? {
        get {
            keychainService.get(valueFor: tokenKey)
        }
        set {
            if let newValue = newValue {
                _ = keychainService.set(value: newValue, for: tokenKey)
            } else {
                _ = keychainService.delete(valueFor: tokenKey)
            }
        }
    }
}
