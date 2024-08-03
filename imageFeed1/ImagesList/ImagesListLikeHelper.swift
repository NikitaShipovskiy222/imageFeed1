

import Foundation
// MARK: - Protocol
protocol ImagesListLikeHelperProtocol {
    func getMethod(for isLike: Bool) -> String
    func getLikeURL(for photoId: String) -> String
    func performLikeRequest(token: String,
                            method: String,
                            url: String,
                            isLike: Bool,
                            photoId: String,
                            completion: @escaping (Result<VoidModel, Error>) -> Void)
    func handleLikeSuccess(isLike: Bool, photoId: String)
    func handleLikeFailure(error: Error, completion: @escaping (Result<VoidModel, Error>) -> Void)
}

// MARK: - Object
final class ImagesListLikeHelper: ImagesListLikeHelperProtocol {
    private let likeNetworkService = GenericNetworkService<VoidModel>()
    
    func getMethod(for isLike: Bool) -> String {
        return isLike ? "POST" : "DELETE"
    }
    
    func getLikeURL(for photoId: String) -> String {
        return "\(APIEndpoints.Photos.photos)/\(photoId)/like"
    }
    
    func performLikeRequest(token: String,
                            method: String,
                            url: String,
                            isLike: Bool,
                            photoId: String,
                            completion: @escaping (Result<VoidModel, Error>) -> Void) {
        likeNetworkService.fetch(parameters: ["token": token],
                                 method: method,
                                 url: url) { result in
            switch result {
            case .success(_):
                self.handleLikeSuccess(isLike: isLike, photoId: photoId)
                completion(.success(VoidModel()))
            case .failure(let error):
                self.handleLikeFailure(error: error, completion: completion)
            }
        }
    }
    
    func handleLikeSuccess(isLike: Bool, photoId: String) {
        Logger.shared.log(.debug,
                          message: "LikeHelper: Лайк успешно изменен",
                          metadata: ["✅": ""])
    }
    
    func handleLikeFailure(error: Error, completion: @escaping (Result<VoidModel, Error>) -> Void) {
        let errorMessage = NetworkErrorHandler.errorMessage(from: error)
        Logger.shared.log(.error,
                          message: "LikeHelper: Ошибка изменения состояния лайка",
                          metadata: ["❌": errorMessage])
        completion(.failure(error))
    }
}

