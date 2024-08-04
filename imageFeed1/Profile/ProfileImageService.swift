
import UIKit

final class ProfileImageService {
    
    // MARK: - Properties
    
    static var shared = ProfileImageService()
    private let urlSession = URLSession.shared
    private let storage = OAuth2TokenStorage()
    private(set) var avatarURL: String?
    private var task: URLSessionTask?
    private var lastUserName: String?
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    
    // MARK: - init
    
    private init() {}
    
    // MARK: - Function
    
    private func makeProfileImageRequest(username: String) -> URLRequest {
        guard let defaultBaseURL = URL(string: Constants.defaultBaseURL) else {
            preconditionFailure("Unable to construct baseUrl")
        }
        var urlComponents = URLComponents()
        urlComponents.path = "/users/\(username)"
        guard let url = urlComponents.url(relativeTo: defaultBaseURL)
         else {
            assertionFailure("Unable to construct avatar url")
            return URLRequest(url: URL(string: "")!)
        }
        guard let token = storage.token else {
            assertionFailure("Failed to make token")
            return URLRequest(url: URL(string: "")!)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print(request)
        return request
    }
    
    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        
        assert(Thread.isMainThread)
        if lastUserName == username { return }
        task?.cancel()
        lastUserName = username
        
        let requestProfileImage = makeProfileImageRequest(username: username)
        let task = urlSession.objectTask(for: requestProfileImage) { [weak self] (result: Result<UserResult, Error>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case.success(let profileImageURL):
                    let avatarURL = profileImageURL.profileImage?.large
                    self.avatarURL = avatarURL
                    completion(.success(avatarURL ?? ""))
                    NotificationCenter.default.post(name: ProfileImageService.didChangeNotification,
                                                    object: self,
                                                    userInfo: ["URL": profileImageURL])
                    self.task = nil
                case .failure(let error):
                    completion(.failure(error))
                    self.lastUserName = nil
                }
            }
        }
        self.task = task
        task.resume()
    }
}
