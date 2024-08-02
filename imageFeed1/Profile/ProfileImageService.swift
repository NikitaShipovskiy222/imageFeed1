

import UIKit

// MARK: - Object
final class ProfileImageService {
    static let shared = ProfileImageService()
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    
    private let serialQueue = DispatchQueue(label: "ProfileImageService.serialQueue")
    private(set) var avatarURL: String?
    
    private init() {}
    
    func clearProfileImage() {
        avatarURL = nil
        Logger.shared.log(.debug,
                          message: "ProfileImageService: Изображение профиля успешно удалено",
                          metadata: ["❎": ""])
    }
}

// MARK: - NetworkService
extension ProfileImageService: NetworkService {
    func makeRequest(parameters: [String: String],
                     method: String,
                     url: String) -> URLRequest? {
        guard let url = URL(string: url) else {
            Logger.shared.log(.error,
                              message: "ProfileImageService: Неверная строка URL" ,
                              metadata: ["❌": url])
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(parameters["token"] ?? "")",
                         forHTTPHeaderField: "Authorization")
        
        Logger.shared.log(.debug,
                          message: "ProfileImageService: Запрос изображения профиля создан:",
                          metadata: ["✅": "\(request)"])
        
        return request
    }
    
    func parse(data: Data) -> UserResult? {
        do {
            let userResult = try JSONDecoder().decode(UserResult.self, from: data)
            Logger.shared.log(.debug,
                              message: "ProfileImageService: Данные изображения профиля успешно обработаны",
                              metadata: ["✅": ""])
            return userResult
        } catch {
            let errorMessage = NetworkErrorHandler.errorMessage(from: error)
            Logger.shared.log(.error,
                              message: "ProfileImageService: Ошибка парсинга изображения профиля",
                              metadata: ["❌": errorMessage])
            return nil
        }
    }
    
    func fetchProfileImageURL(username: String,
                              token: String,
                              completion: @escaping (Result<String, Error>) -> Void) {
        serialQueue.async { [weak self] in
            guard let self else { return }
            self.fetchUserProfile(username: username, token: token) { [weak self] result in
                guard let self = self else { return }
                self.handleFetchUserProfileResult(result: result, completion: completion)
            }
        }
    }
    
    private func fetchUserProfile(username: String, token: String, completion: @escaping (Result<UserResult, Error>) -> Void) {
        let parameters = ["username": username, "token": token]
        let url = APIEndpoints.Profile.profile(username: username)
        
        self.fetch(parameters: parameters, method: "GET", url: url, completion: completion)
    }
    
    private func handleFetchUserProfileResult(result: Result<UserResult, Error>, completion: @escaping (Result<String, Error>) -> Void) {
        switch result {
        case .success(let userResult):
            self.processUserResult(userResult, completion: completion)
        case .failure(let error):
            self.handleFetchError(error, completion: completion)
        }
    }
    
    private func processUserResult(_ userResult: UserResult, completion: @escaping (Result<String, Error>) -> Void) {
        if let imageURL = userResult.profileImage {
            let profileImageURL = imageURL.large
            self.avatarURL = profileImageURL
            NotificationCenter.default.post(name: ProfileImageService.didChangeNotification,
                                            object: self,
                                            userInfo: ["URL": profileImageURL])
            DispatchQueue.main.async {
                Logger.shared.log(.debug,
                                  message: "ProfileImageService: URL изображения профиля успешно получены",
                                  metadata: ["✅ URL": profileImageURL])
                completion(.success(profileImageURL))
            }
        } else {
            DispatchQueue.main.async {
                Logger.shared.log(.debug,
                                  message: "ProfileImageService: URL-адрес изображения профиля не найден",
                                  metadata: ["❗️": ""])
                completion(.success(""))
            }
        }
    }
    
    private func handleFetchError(_ error: Error, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.async {
            let errorMessage = NetworkErrorHandler.errorMessage(from: error)
            Logger.shared.log(.error,
                              message: "ProfileImageService: Не удалось получить URL изображения профиля",
                              metadata: ["❌": errorMessage])
            completion(.failure(error))
        }
    }
}
