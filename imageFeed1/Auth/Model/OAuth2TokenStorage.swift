
import Foundation

protocol OAuth2TokenStorageProtocol {
    var token: String? { get }
}

final class OAuth2TokenStorage: OAuth2TokenStorageProtocol {
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
                Logger.shared.log(.debug,
                                  message: "OAuth2TokenStorage: Токен успешно успешно сохранен в KeychainService",
                                  metadata: ["✅": "\(newValue)"])
            } else {
                _ = keychainService.delete(valueFor: tokenKey)
                Logger.shared.log(.error,
                                  message: "OAuth2TokenStorage: Ошибка сохранения токена в KeychainService",
                                  metadata: ["❌": ""])
            }
        }
    }
    
    func logout() {
        _ = keychainService.delete(valueFor: tokenKey)
        Logger.shared.log(.debug,
                          message: "OAuth2TokenStorage: Токен успешно удален из KeychainService",
                          metadata: ["❎": ""])
    }
}

