

import Foundation
// MARK: - Object
final class OAuth2Service {
    
    static let shared = OAuth2Service()
    
    private let oAuth2TokenStorage = OAuth2TokenStorage.shared
    private let serialQueue = DispatchQueue(label: "OAuth2Service.serialQueue")
    private var activeRequests: [String: [(Result<String, Error>) -> Void]] = [:]
    
    private init() {}
}

// MARK: - NetworkService
extension OAuth2Service: NetworkService {
    func makeRequest(parameters: [String: String],
                     method: String,
                     url: String) -> URLRequest? {
        var components = URLComponents(string: url)
        components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components?.url else {
            Logger.shared.log(.error,
                              message: "OAuth2Service: Невозможно создать URL с параметрами:",
                              metadata: ["❌": "\(parameters)"])
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components?.percentEncodedQuery?.data(using: .utf8)
        
        Logger.shared.log(.debug,
                          message: "OAuth2Service: Запрос на создание:",
                          metadata: ["✅": "\(request)"])
        
        return request
    }
    
    func parse(data: Data) -> OAuthTokenResponseBody? {
        do {
            let tokenResponse = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
            self.oAuth2TokenStorage.token = tokenResponse.accessToken
            Logger.shared.log(.debug,
                              message: "OAuth2Service: Access token сохранен",
                              metadata: ["✅": tokenResponse.accessToken])
            return tokenResponse
        } catch {
            let errorMessage = NetworkErrorHandler.errorMessage(from: error)
            Logger.shared.log(.error,
                              message: "OAuth2Service: Ошибка обработки токена:",
                              metadata: ["❌": errorMessage])
            return nil
        }
    }
    
    func fetchOAuthToken(code: String,
                         completion: @escaping (Result<String, Error>) -> Void) {
        serialQueue.async { [weak self] in
            guard let self else { return }

            if self.isActiveRequest(for: code, completion: completion) {
                return
            }

            let parameters = self.createOAuthParameters(with: code)
            
            Logger.shared.log(.debug,
                              message: "OAuth2Service: Получение токена OAuth с кодом:",
                              metadata: ["✅": code])
            
            self.performOAuthRequest(with: parameters, for: code)
        }
    }

    private func isActiveRequest(for code: String,
                                 completion: @escaping (Result<String, Error>) -> Void) -> Bool {
        if activeRequests[code] != nil {
            activeRequests[code]?.append(completion)
            return true
        } else {
            activeRequests[code] = [completion]
            return false
        }
    }

    private func createOAuthParameters(with code: String) -> [String: String] {
        [
            "client_id": Constants.accessKey,
            "client_secret": Constants.secretKey,
            "redirect_uri": Constants.redirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]
    }

    private func performOAuthRequest(with parameters: [String: String], for code: String) {
        fetch(parameters: parameters,
              method: "POST",
              url: APIEndpoints.OAuth.token) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self else { return }

            self.handleOAuthResponse(result, for: code)
        }
    }

    private func handleOAuthResponse(_ result: Result<OAuthTokenResponseBody, Error>, for code: String) {
        serialQueue.async { [weak self] in
            guard let self else { return }
            
            let completions = self.activeRequests.removeValue(forKey: code) ?? []
            for completion in completions {
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        Logger.shared.log(.debug,
                                          message: "OAuth2Service: Токен OAuth успешно получен",
                                          metadata: ["✅": response.accessToken])
                        completion(.success(response.accessToken))
                    case .failure(let error):
                        let errorMessage = NetworkErrorHandler.errorMessage(from: error)
                        Logger.shared.log(.error,
                                          message: "OAuth2Service: Не удалось получить токен OAuth",
                                          metadata: ["❌": errorMessage])
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}
