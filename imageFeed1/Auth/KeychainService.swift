
import Foundation
import Security
// MARK: - protocol
protocol KeychainServiceProtocol {
    func set(value: String, for key: String) -> Bool
    func get(valueFor key: String) -> String?
    func delete(valueFor key: String) -> Bool
}
// MARK: - object
final class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
}
// MARK: - KeychainServiceProtocol
extension KeychainService: KeychainServiceProtocol {
    
    func set(value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        return status == errSecSuccess
    }
    
    func get(valueFor key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
                let data = dataTypeRef as? Data,
                let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    func delete(valueFor key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        return status == errSecSuccess
    }
}
