

import Foundation

// MARK: - Protocol
protocol ImagesListPhotosHelperProtocol {
    func performFetchPhotosRequest(page: Int, token: String, completion: @escaping (Result<[Photo], Error>) -> Void)
    func handleFetchPhotosFailure(_ error: Error, completion: @escaping (Result<[Photo], Error>) -> Void)
    func mapToPhotos(photoResult: PhotoResult) -> Photo
}

// MARK: - Object
final class ImagesListPhotosHelper: ImagesListPhotosHelperProtocol {
    private let photosNetworkService = GenericNetworkService<[PhotoResult]>()
    private let dateFormatter = ISO8601DateFormatter()
    private var currentPage = 1
    private let maxPages = 3

    func performFetchPhotosRequest(page: Int, token: String, completion: @escaping (Result<[Photo], Error>) -> Void) {
        guard currentPage <= maxPages else {
            completion(.success([]))
            return
        }
        
        let parameters = ["page": "\(page)", "per_page": "5", "token": token]
        photosNetworkService.fetch(parameters: parameters,
                                   method: "GET",
                                   url: APIEndpoints.Photos.photos) { result in
            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.compactMap { self.mapToPhotos(photoResult: $0) }
                self.currentPage += 1
                completion(.success(newPhotos))
            case .failure(let error):
                self.handleFetchPhotosFailure(error, completion: completion)
            }
        }
    }
    
    func handleFetchPhotosFailure(_ error: Error, completion: @escaping (Result<[Photo], Error>) -> Void) {
        let errorMessage = NetworkErrorHandler.errorMessage(from: error)
        Logger.shared.log(.error,
                          message: "PhotosHelper: Ошибка при получении фотографий",
                          metadata: ["❌": errorMessage])
        completion(.failure(error))
    }

    func mapToPhotos(photoResult: PhotoResult) -> Photo {
        let date = photoResult.createdAt.flatMap { dateFormatter.date(from: $0) }
        
        return Photo(id: photoResult.id,
                     size: CGSize(width: photoResult.width, height: photoResult.height),
                     createdAt: date,
                     welcomeDescription: photoResult.description,
                     regularImageURL: photoResult.urls.regular,
                     largeImageURL: photoResult.urls.full,
                     isLiked: photoResult.likedByUser)
    }
}
