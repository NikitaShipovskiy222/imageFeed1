

import Foundation
import Kingfisher
// MARK: - Protocol
protocol ImagesListServiceProtocol {
    var photos: [Photo] { get }
    func fetchPhotosNextPage(with token: String)
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<VoidModel, Error>) -> Void)
}
// MARK: - Object
final class ImagesListService {
    
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    private let likeHelper: ImagesListLikeHelperProtocol?
    private let photosHelper: ImagesListPhotosHelperProtocol?
    
    private (set) var photos = [Photo]()
    private var lastLoadedPage: Int?
    private var isLoading = false
    
    private let synchronizationQueue = DispatchQueue(label: "ImagesListService.serialQueue")
    private let semaphore = DispatchSemaphore(value: 1)
    
    private init() {
        self.likeHelper = ImagesListLikeHelper()
        self.photosHelper = ImagesListPhotosHelper()
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

// MARK: - ImagesListServiceProtocol
extension ImagesListService: ImagesListServiceProtocol {
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<VoidModel, Error>) -> Void) {
        synchronizationQueue.async { [weak self] in
            guard let self else { return }
            
            self.semaphore.wait()
            defer { self.semaphore.signal() }
            
            guard let method = self.likeHelper?.getMethod(for: isLike),
                  let url = self.likeHelper?.getLikeURL(for: photoId) else { return }
            
            guard let token = self.getToken() else {
                completion(.failure(NetworkError.errorFetchingAccessToken))
                Logger.shared.log(.error,
                                  message: "ImagesListService: Токен доступа недоступен или пуст",
                                  metadata: ["❌": ""])
                return
            }
            
            self.likeHelper?.performLikeRequest(token: token,
                                               method: method,
                                               url: url,
                                               isLike: isLike,
                                               photoId: photoId,
                                               completion: completion)
        }
    }
    
    func fetchPhotosNextPage(with token: String) {
        synchronizationQueue.async { [weak self] in
            guard let self else { return }
            
            self.semaphore.wait()
            defer { self.semaphore.signal() }
            
            guard !self.isLoading else { return }
            self.isLoading = true
            let nextPage = (self.lastLoadedPage ?? 0) + 1
            
            self.photosHelper?.performFetchPhotosRequest(page: nextPage,
                                                        token: token) { [weak self] result in
                guard let self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let newPhotos):
                    self.lastLoadedPage = nextPage
                    self.addPhotos(newPhotos)
                    Logger.shared.log(.debug,
                                      message: "ImagesListService: Изображения успешно получены",
                                      metadata: ["✅": ""])
                    NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
                case .failure(let error):
                    let errorMessage = NetworkErrorHandler.errorMessage(from: error)
                    Logger.shared.log(.error,
                                      message: "ImagesListService: Не удалось получить изображения",
                                      metadata: ["❌": errorMessage])
                }
            }
        }
    }
}

// MARK: - Token
extension ImagesListService {
    func getToken() -> String? {
        guard let token = OAuth2TokenStorage.shared.token, !token.isEmpty else {
            return nil
        }
        return token
    }
}
