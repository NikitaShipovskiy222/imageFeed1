

import UIKit
// MARK: - Protocols
protocol ImagesListViewControllerProtocol: AnyObject {
    func updateImagesList(startIndex: Int, endIndex: Int)
    func reloadTableView()
    func showStubImageView(_ isHidden: Bool)
}

// MARK: - Object
final class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {
    
    var presenter: ImagesListPresenterProtocol?
    
    let refreshControl = UIRefreshControl()
    
    lazy var stubImageView = UIImageView(image: UIImage(named: "Stub"))
    lazy var tableView = UITableView()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        refreshControl.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        
        configureTableView()
        setupConstraints()
        presenter?.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter?.fetchPhotos()
    }
    
    func configure(_ presenter: ImagesListPresenterProtocol) {
        self.presenter = presenter
        self.presenter?.view = self
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.accessibilityIdentifier = "ImagesListTableView"
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
    
    @objc func refreshTableView() {
        presenter?.fetchPhotos()
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    func updateImagesList(startIndex: Int, endIndex: Int) {
        showStubImageView(true)
        let indexPaths = (startIndex...endIndex).map { IndexPath(row: $0, section: 0) }
        UIView.performWithoutAnimation { [weak self] in
            self?.tableView.performBatchUpdates({
                self?.tableView.insertRows(at: indexPaths, with: .none)
            })
        }
    }
    
    func reloadTableView() {
        tableView.reloadData()
    }
    
    func showStubImageView(_ isHidden: Bool) {
        stubImageView.isHidden = isHidden
    }
    
    func makeSingleImageViewController(with imageURL: URL) -> SingleImageViewController {
        let singleImageViewController = SingleImageViewController()
        singleImageViewController.configure(withImageURL: imageURL)
        singleImageViewController.modalPresentationStyle = .fullScreen
        return singleImageViewController
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let numbersOfPhotos = presenter?.numberOfPhotos() else { return 0 }
        return numbersOfPhotos
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath) as! ImagesListCell
        if let photo = presenter?.photo(at: indexPath.row),
           let dateText = presenter?.format(date: photo.createdAt), let presenter = presenter as? ImagesListPresenter {
            cell.configure(with: photo, dateText: dateText, presenter: presenter)
            cell.accessibilityIdentifier = "cell_\(indexPath.row)"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let photo = presenter?.photo(at: indexPath.row) else { return UITableView.automaticDimension }
        let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - insets.left - insets.right
        let imageWidth = CGFloat(photo.size.width)
        let scale = imageViewWidth / imageWidth
        return CGFloat(photo.size.height) * scale + insets.top + insets.bottom
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let numbersOfPhotos = presenter?.numberOfPhotos() else { return }
        if indexPath.row == numbersOfPhotos - 1 {
            presenter?.fetchPhotos()
        }
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let photo = presenter?.photo(at: indexPath.row),
              let imageURL = URL(string: photo.largeImageURL) else { return }
        
        let singleImageViewController = makeSingleImageViewController(with: imageURL)
        present(singleImageViewController, animated: true, completion: nil)
    }
}
