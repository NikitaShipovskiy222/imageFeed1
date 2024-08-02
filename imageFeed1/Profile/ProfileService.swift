

import UIKit

// MARK: - Object
final class ProfileService {
    
    static let shared = ProfileService()
    
    private(set) var profile: Profile?
    private let serialQueue = DispatchQueue(label: "ProfileService.serialQueue")
    
    private init() {}
    
    var isProfileLoaded: Bool {
        return profile != nil
    }
    
    func clearProfileData() {
        profile = nil
        Logger.shared.log(.debug,
                          message: "ProfileService: Данные профиля успешно удалены",
                          metadata: ["❎": ""])
    }
}
// MARK: - NetworkService
extension ProfileService: NetworkService {
    func makeRequest(parameters: [String: String], method: String, url: String) -> URLRequest? {
        guard let url = URL(string: url) else {
            Logger.shared.log(.error, message: "ProfileService: Неверная строка URL",
                              metadata: ["❌": url])
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(parameters["token"] ?? "")", forHTTPHeaderField: "Authorization")
        
        Logger.shared.log(.debug,
                          message: "ProfileService: Запрос данных профиля создан:",
                          metadata: ["✅": "\(request)"])
        
        return request
    }
    
    func parse(data: Data) -> Profile? {
        do {
            let userProfile = try JSONDecoder().decode(ProfileResult.self, from: data)
            Logger.shared.log(.debug,
                              message: "ProfileService: Данные профиля успешно обработаны",
                              metadata: ["✅" : ""])
            return Profile(userProfile: userProfile)
        } catch {
            Logger.shared.log(.error,
                              message: "ProfileService: Ошибка парсинга" ,
                              metadata: ["❌": error.localizedDescription])
            return nil
        }
    }
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        serialQueue.async { [weak self] in
            guard let self else { return }
            self.fetch(parameters: ["token": token],
                       method: "GET",
                       url: APIEndpoints.Profile.me) { (result: Result<Profile, Error>) in
                switch result {
                case .success(let profile):
                    DispatchQueue.main.async {
                        self.profile = profile
                        Logger.shared.log(.debug,
                                          message: "ProfileService: Данные профиля успешно получены",
                                          metadata: ["✅": ""])
                        completion(.success(profile))
                    }
                case .failure(let error):
                    let errorMessage = NetworkErrorHandler.errorMessage(from: error)
                    DispatchQueue.main.async {
                        Logger.shared.log(.error,
                                          message: "ProfileService: Не удалось загрузить профиль",
                                          metadata: ["❌": errorMessage])
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}
