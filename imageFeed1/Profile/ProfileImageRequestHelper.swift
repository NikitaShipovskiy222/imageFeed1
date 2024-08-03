

import Foundation

// MARK: - Protocol
protocol ProfileImageRequestHelperProtocol {
    static func createRequest(urlString: String, method: String, token: String) -> URLRequest?
}

// MARK: - Object
final class ProfileImageRequestHelper: ProfileImageRequestHelperProtocol {
    static func createRequest(urlString: String, method: String, token: String) -> URLRequest? {
        guard let url = URL(string: urlString) else {
            Logger.shared.log(.error,
                              message: "ProfileImageRequestHelper: Неверная строка URL",
                              metadata: ["❌": urlString])
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        Logger.shared.log(.debug,
                          message: "ProfileImageRequestHelper: Запрос создан",
                          metadata: ["✅": "\(request)"])

        return request
    }
}
