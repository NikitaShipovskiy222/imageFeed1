

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
            Logger.shared.log(.error, message: "Unable to construct URL with parameters: \(parameters)")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components?.percentEncodedQuery?.data(using: .utf8)
        
        Logger.shared.log(.debug, message: "Request created: \(request)")
        
        return request
    }
    
    func parse(data: Data) -> OAuthTokenResponseBody? {
        do {
            let tokenResponse = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
            self.oAuth2TokenStorage.token = tokenResponse.accessToken
            Logger.shared.log(.debug, message: "Access token saved", metadata: ["token": tokenResponse.accessToken])
            return tokenResponse
        } catch {
            Logger.shared.log(.error, message: "Token parsing error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchOAuthToken(code: String,
                         completion: @escaping (Result<String, Error>) -> Void) {
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.activeRequests[code] != nil {
                self.activeRequests[code]?.append(completion)
                return
            } else {
                self.activeRequests[code] = [completion]
            }
            
            let parameters = [
                "client_id": Constants.accessKey,
                "client_secret": Constants.secretKey,
                "redirect_uri": Constants.redirectURI,
                "code": code,
                "grant_type": "authorization_code"
            ]
            
            Logger.shared.log(.debug, message: "Fetching OAuth token with code: \(code)")
            
            self.fetch(parameters: parameters,
                       method: "POST",
                       url: APIEndpoints.OAuth.token) { (result: Result<OAuthTokenResponseBody, Error>) in
                self.serialQueue.async {
                    let completions = self.activeRequests.removeValue(forKey: code) ?? []
                    for completion in completions {
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let response):
                                Logger.shared.log(.debug, message: "Successfully fetched OAuth token", metadata: ["token": response.accessToken])
                                completion(.success(response.accessToken))
                            case .failure(let error):
                                Logger.shared.log(.error, message: "Failed to fetch OAuth token", metadata: ["error": error.localizedDescription])
                                completion(.failure(error))
                            }
                        }
                    }
                }
            }
        }
    }
}
