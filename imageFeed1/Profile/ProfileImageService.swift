
import UIKit
// MARK: - Protocol
protocol ProfileImageServiceProtocol {
    func fetchProfileImageURL(username: String, token: String, completion: @escaping (Result<String, Error>) -> Void)
}

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
    func makeRequest(parameters: [String: String], method: String, url: String) -> URLRequest? {
        return ProfileImageRequestHelper.createRequest(urlString: url, method: method, token: parameters["token"] ?? "")
    }

    func parse(data: Data) -> UserResult? {
        return ProfileImageResponseHelper.parseUserResult(from: data)
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
            ProfileImageResponseHelper.handleFetchError(error, completion: completion)
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
}

// MARK: - ProfileImageServiceProtocol
extension ProfileImageService: ProfileImageServiceProtocol {
    
    func fetchProfileImageURL(username: String, token: String, completion: @escaping (Result<String, Error>) -> Void) {
        serialQueue.async { [weak self] in
            guard let self else { return }
            self.fetchUserProfile(username: username, token: token) { [weak self] result in
                guard let self = self else { return }
                self.handleFetchUserProfileResult(result: result, completion: completion)
            }
        }
    }
}
