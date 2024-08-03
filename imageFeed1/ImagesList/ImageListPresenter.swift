//
//  ImagesListPresenter.swift
//  ImageFeed
//
//  Created by Konstantin Lyashenko on 16.07.2024.
//

import Foundation
// MARK: - Protocols
protocol ImagesListPresenterProtocol {
    var view: ImagesListViewControllerProtocol? { get set }
    func viewDidLoad()
    func fetchPhotos()
    func numberOfPhotos() -> Int
    func photo(at index: Int) -> Photo?
    func format(date: Date?) -> String
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<VoidModel, Error>) -> Void)
}

// MARK: - Object
final class ImagesListPresenter {
    
    weak var view: ImagesListViewControllerProtocol?
    private let imagesListService: ImagesListServiceProtocol
    private let storage: OAuth2TokenStorageProtocol
    private let dateFormatter = DateFormatter.longDateFormatter
    
    init(view: ImagesListViewControllerProtocol,
         imagesListService: ImagesListServiceProtocol,
         storage: OAuth2TokenStorageProtocol) {
        self.view = view
        self.imagesListService = imagesListService
        self.storage = storage
    }
    
    func viewDidLoad() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleImagesListServiceDidChangeNotification(_:)),
                                               name: ImagesListService.didChangeNotification,
                                               object: nil)
    }
    
    @objc private func handleImagesListServiceDidChangeNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let startIndex = userInfo["startIndex"] as? Int,
              let endIndex = userInfo["endIndex"] as? Int else {
            
            view?.reloadTableView()
            view?.showStubImageView(!imagesListService.photos.isEmpty)
            return
        }
        view?.updateImagesList(startIndex: startIndex, endIndex: endIndex)
    }
}

// MARK: - ImagesListPresenterProtocol
extension ImagesListPresenter: ImagesListPresenterProtocol {
    func fetchPhotos() {
        if let token = storage.token {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.imagesListService.fetchPhotosNextPage(with: token)
            }
        }
    }
    
    func numberOfPhotos() -> Int {
        return imagesListService.photos.count
    }
    
    func photo(at index: Int) -> Photo? {
        guard index < imagesListService.photos.count else { return nil }
        return imagesListService.photos[index]
    }
    
    func format(date: Date?) -> String {
        guard let date = date else { return "Дата неизвестна" }
        let formatDate = dateFormatter.string(from: date)
        return formatDate
    }
    
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<VoidModel, Error>) -> Void) {
        imagesListService.changeLike(photoId: photoId, isLike: isLike, completion)
    }
}
