//
//  OAuth2Service.swift
//  ImageFeed
//
//  Created by Konstantin Lyashenko on 04.06.2024.
//

import Foundation

// MARK: - Protocol
protocol OAuth2ServiceProtocol {
    func makeOAuthTokenRequest(code: String) -> URLRequest?
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void)
}

// MARK: - Object
final class OAuth2Service: OAuth2ServiceProtocol {
    static let shared = OAuth2Service()
    
    private let oAuth2TokenStorage = OAuth2TokenStorage.shared
    
    private init() {}

    func makeOAuthTokenRequest(code: String) -> URLRequest? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "unsplash.com"
        components.path = "/oauth/token"

        let bodyParameters = [
            "client_id": Constants.accessKey,
            "client_secret": Constants.secretKey,
            "redirect_uri": Constants.redirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]

        components.queryItems = bodyParameters.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = components.url else {
            print(NetworkError.unableToConstructURL.localizedDescription)
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        return request
    }

    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(NetworkError.unableToConstructURL))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else { return }

            let fulfillCompletionOnTheMainThread: (Result<String, Error>) -> Void = { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }

            if let error = error {
                fulfillCompletionOnTheMainThread(.failure(error))
                return
            }

            guard let response = response as? HTTPURLResponse else {
                fulfillCompletionOnTheMainThread(.failure(NetworkError.unknownError))
                return
            }

            switch response.statusCode {
            case 200..<300:
                guard let data = data, let token = self.parseAndStoreToken(data: data) else {
                    fulfillCompletionOnTheMainThread(.failure(NetworkError.emptyData))
                    return
                }
                fulfillCompletionOnTheMainThread(.success(token))

            case 400:
                fulfillCompletionOnTheMainThread(.failure(NetworkError.invalidURLString))
            case 401:
                fulfillCompletionOnTheMainThread(.failure(NetworkError.errorFetchingAccessToken))
            case 403:
                fulfillCompletionOnTheMainThread(.failure(NetworkError.unauthorized))
            case 404:
                fulfillCompletionOnTheMainThread(.failure(NetworkError.notFound))
            case 422:
                fulfillCompletionOnTheMainThread(.failure(NetworkError.unknownError))
            case 500, 503:
                fulfillCompletionOnTheMainThread(.failure(NetworkError.serviceUnavailable))
            default:
                fulfillCompletionOnTheMainThread(.failure(NetworkError.unknownError))
            }
        }
        task.resume()
    }

    private func parseAndStoreToken(data: Data) -> String? {
        do {
            let tokenResponse = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
            let accessToken = tokenResponse.accessToken
            self.oAuth2TokenStorage.token = accessToken
            print("Access token saved: \(accessToken)")
            return accessToken
        } catch {
            print("Token parsing error: \(error.localizedDescription)")
            return nil
        }
    }
}
