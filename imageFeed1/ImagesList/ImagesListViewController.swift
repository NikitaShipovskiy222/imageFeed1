

import UIKit

final class ImagesListViewController: UIViewController {
    
    private let storage = OAuth2TokenStorage.shared
    private let imagesListService = ImagesListService.shared
    private let refreshControl = UIRefreshControl()
    
    private lazy var stubImageView = UIImageView(image: UIImage(named: "Stub"))
    private lazy var tableView = UITableView()

    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "ru_RU")
        return dateFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        
        if let tabBarItem = self.tabBarItem {
            let imageInset = UIEdgeInsets(top: 13, left: 0, bottom: -13, right: 0)
            tabBarItem.imageInsets = imageInset
        }
        refreshControl.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        
        configureTableView()
        setupConstraints()
        setupNotifications()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchPhotos()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .ypBlack
        tableView.addSubview(refreshControl)
        tableView.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)
    }
    
    private func setupConstraints() {
        [tableView, stubImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            stubImageView.widthAnchor.constraint(equalToConstant: 83),
            stubImageView.heightAnchor.constraint(equalToConstant: 75),
            stubImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stubImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func refreshTableView() {
        fetchPhotos()
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
}

// MARK: - Observer
private extension ImagesListViewController {
    
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
            tableView.reloadData()
            stubImageView.isHidden = !imagesListService.photos.isEmpty
            return
        }
        let indexPaths = (startIndex...endIndex).map { IndexPath(row: $0, section: 0) }

        UIView.performWithoutAnimation { [weak self] in
            guard let self else { return }
            
            self.tableView.performBatchUpdates({
                self.tableView.insertRows(at: indexPaths, with: .none)
            }, completion: { _ in
                self.stubImageView.isHidden = !self.imagesListService.photos.isEmpty
            })
        }
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imagesListService.photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath) as! ImagesListCell
        configCell(cell, for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < imagesListService.photos.count else { return 0 }
        
        let photo = imagesListService.photos[indexPath.row]
        
        let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - insets.left - insets.right
        let imageWidth = CGFloat(photo.size.width)
        let scale = imageViewWidth / imageWidth
        let cellHeight = CGFloat(photo.size.height) * scale + insets.top + insets.bottom
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == imagesListService.photos.count - 1 {
            fetchPhotos()
        }
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let singleImageViewController = SingleImageViewController()
        
        guard indexPath.row < imagesListService.photos.count else { return }
        
        let photo = imagesListService.photos[indexPath.row]
        guard let imageURL = URL(string: photo.largeImageURL) else { return }
        
        singleImageViewController.configure(withImageURL: imageURL)
        singleImageViewController.modalPresentationStyle = .fullScreen
        
        DispatchQueue.main.async { // тут цикл исключен
            self.present(singleImageViewController, animated: true, completion: nil)
        }
    }
}

// MARK: - Configure Images
extension ImagesListViewController {
    
    private func fetchPhotos() {
        if let token = storage.token {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.imagesListService.fetchPhotosNextPage(with: token)
            }
        }
    }
    
    private func configCell(_ cell: ImagesListCell, for indexPath: IndexPath) {
        cell.backgroundColor = .ypBlack
        cell.selectionStyle = .none
        
        guard indexPath.row < imagesListService.photos.count else { return }
        
        var photo = imagesListService.photos[indexPath.row]
        let imageURL = URL(string: photo.regularImageURL)
        
        var dateText: String
        if let createdAt = photo.createdAt {
            dateText = dateFormatter.string(from: createdAt)
        } else {
            dateText = "Дата неизвестна"
        }
        
        cell.configure(withImageURL: imageURL, text: dateText, isLiked: photo.isLiked, photoId: photo.id)
        
        cell.likeButtonAction = { [weak self] (photoId, shouldLike) in
            guard let self else { return }
            self.imagesListService.changeLike(photoId: photoId, isLike: shouldLike) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        photo.isLiked = shouldLike
                        cell.isLiked = shouldLike
                    }
                case .failure(let error):
                    _ = NetworkErrorHandler.errorMessage(from: error)
                }
            }
        }
    }
}
