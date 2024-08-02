

import Foundation
import Kingfisher

final class ImagesListService {
    
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    private let photosNetworkService = GenericNetworkService<[PhotoResult]>()
    private let likeNetworkService = GenericNetworkService<VoidModel>()
    
    private (set) var photos = [Photo]()
    private var lastLoadedPage: Int?
    private var isLoading = false
    
    private let synchronizationQueue = DispatchQueue(label: "ImagesListService.serialQueue")
    private let semaphore = DispatchSemaphore(value: 1)
    
    private let dateFormatter = ISO8601DateFormatter()
    
    private init() {
        loadLikes()
    }
    
    private func addPhotos(_ newPhotos: [Photo]) {
        let startIndex = photos.count
        photos.append(contentsOf: newPhotos)
        let endIndex = photos.count - 1
        
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification,
                                        object: nil,
                                        userInfo: ["startIndex": startIndex, "endIndex": endIndex])
    }
    
    func clearImagesList() {
        photos = []
        lastLoadedPage = nil
        Logger.shared.log(.debug,
                          message: "ImagesListService: Массив изображений пуст",
                          metadata: ["❎": ""])
    }
}

// MARK: - NetworkService for Likes
extension ImagesListService {
    
    private func saveLikes() {
        let likes = photos.map { [$0.id: $0.isLiked] }
        UserDefaults.standard.set(likes, forKey: "photoLikes")
    }
    
    private func loadLikes() {
        guard let likes = UserDefaults.standard.array(forKey: "photoLikes") as? [[String: Bool]] else { return }
        for like in likes {
            if let id = like.keys.first, let isLiked = like.values.first {
                if let index = photos.firstIndex(where: { $0.id == id }) {
                    photos[index].isLiked = isLiked
                }
            }
        }
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<VoidModel, Error>) -> Void) {
        synchronizationQueue.async { [weak self] in
            guard let self else { return }
            
            self.semaphore.wait()
            defer { self.semaphore.signal() }
            
            let method = self.getMethod(for: isLike)
            let url = self.getLikeURL(for: photoId)
            
            guard let token = self.getToken() else {
                completion(.failure(NetworkError.errorFetchingAccessToken))
                Logger.shared.log(.error,
                                  message: "ImagesListService: Токен доступа недоступен или пуст",
                                  metadata: ["❌": ""])
                return
            }
            
            self.performLikeRequest(token: token, method: method, url: url, isLike: isLike, photoId: photoId, completion: completion)
        }
    }
    
    private func getMethod(for isLike: Bool) -> String {
        return isLike ? "POST" : "DELETE"
    }
    
    private func getLikeURL(for photoId: String) -> String {
        return "\(APIEndpoints.Photos.photos)/\(photoId)/like"
    }
    
    private func getToken() -> String? {
        guard let token = OAuth2TokenStorage.shared.token, !token.isEmpty else {
            return nil
        }
        return token
    }
    
    private func performLikeRequest(token: String, method: String, url: String, isLike: Bool, photoId: String, completion: @escaping (Result<VoidModel, Error>) -> Void) {
        self.likeNetworkService.fetch(parameters: ["token": token],
                                      method: method,
                                      url: url) { [weak self] result in
            guard let self else { return }
            
            self.handleLikeResponse(result, isLike: isLike, photoId: photoId, completion: completion)
        }
    }
    
    private func handleLikeResponse(_ result: Result<VoidModel, Error>, isLike: Bool, photoId: String, completion: @escaping (Result<VoidModel, Error>) -> Void) {
        switch result {
        case .success(_):
            self.handleLikeSuccess(isLike: isLike, photoId: photoId)
            completion(.success(VoidModel()))
        case .failure(let error):
            self.handleLikeFailure(error: error, completion: completion)
        }
    }
    
    private func handleLikeSuccess(isLike: Bool, photoId: String) {
        if isLike {
            Logger.shared.log(.debug,
                              message: "ImagesListService: Лайк поставлен",
                              metadata: ["✅": ""])
        } else {
            Logger.shared.log(.debug,
                              message: "ImagesListService: Лайк снят",
                              metadata: ["✅": ""])
        }
        
        if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
            self.photos[index].isLiked = isLike
            self.saveLikes()
        }
    }
    
    private func handleLikeFailure(error: Error, completion: @escaping (Result<VoidModel, Error>) -> Void) {
        completion(.failure(error))
        let errorMessage = NetworkErrorHandler.errorMessage(from: error)
        Logger.shared.log(.error,
                          message: "ImagesListService: Ошибка при изменении состояния лайка",
                          metadata: ["❌": errorMessage])
    }
    
}

// MARK: - NetworkService for Image
extension ImagesListService {
    
    func fetchPhotosNextPage(with token: String) {
        synchronizationQueue.async { [weak self] in // тут я вообзе не понимаю зачем ослаблять ссылку, если при вызове я и так это делаю
            guard let self else { return }
            
            self.semaphore.wait()
            defer { self.semaphore.signal() }
            
            guard !self.isLoading else { return }
            self.isLoading = true
            let nextPage = (self.lastLoadedPage ?? 0) + 1
            
            self.performFetchPhotosRequest(page: nextPage, token: token)
        }
    }
    
    private func performFetchPhotosRequest(page: Int, token: String) {
        let parameters = ["page": "\(page)", "per_page": "10", "token": token]
        self.photosNetworkService.fetch(parameters: parameters, method: "GET", url: APIEndpoints.Photos.photos) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            self.handleFetchPhotosResponse(result, page: page)
        }
    }
    
    private func handleFetchPhotosResponse(_ result: Result<[PhotoResult], Error>, page: Int) {
        switch result {
        case .success(let photoResults):
            self.handleFetchPhotosSuccess(photoResults, page: page)
        case .failure(let error):
            self.handleFetchPhotosFailure(error)
        }
    }
    
    private func handleFetchPhotosSuccess(_ photoResults: [PhotoResult], page: Int) {
        let newPhotos = photoResults.compactMap { mapToPhotos(photoResult: $0) }
        self.lastLoadedPage = page
        self.addPhotos(newPhotos)
        Logger.shared.log(.debug,
                          message: "ImagesListService: Изображения успешно получены",
                          metadata: ["✅": ""])
        
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
    }
    
    private func handleFetchPhotosFailure(_ error: Error) {
        let errorMessage = NetworkErrorHandler.errorMessage(from: error)
        Logger.shared.log(.error,
                          message: "ImagesListService: Не удалось получить изображения",
                          metadata: ["❌": errorMessage])
    }
}

// MARK: - Map to Photos
extension ImagesListService {
    
    private func mapToPhotos(photoResult: PhotoResult) -> Photo {
        let date = photoResult.createdAt.flatMap { dateFormatter.date(from: $0) }
        
        return Photo(id: photoResult.id,
                     size: CGSize(width: photoResult.width,
                                  height: photoResult.height),
                     createdAt: date,
                     welcomeDescription: photoResult.description,
                     regularImageURL: photoResult.urls.regular,
                     largeImageURL: photoResult.urls.full,
                     isLiked: photoResult.likedByUser)
    }
}
