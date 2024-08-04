
import UIKit
import Kingfisher

class ProfileViewController: UIViewController {
    
    // MARK: - View
    
    private let avatarImageView = UIImageView()
    private let logoutButton = UIButton()
    private var nameLabel = UILabel()
    private var loginNameLabel = UILabel()
    private var descriptionLabel = UILabel()
    
    // MARK: - Properties
    
    private var storage = OAuth2TokenStorage.shared
    private var profileService = ProfileService.shared
    var profile: Profile?
    private var profileImageServiceObserver: NSObjectProtocol?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayer()
    }
    
    // MARK: - Action
    
    @objc
    private func didTapLogoutButton() {
        storage.logout()
        
    }
}

// MARK: - Extension

extension ProfileViewController {
    
    // MARK: - Setup layer function
    
    func setupLayer() {
        view.backgroundColor = .ypBlack
        configureAvatarImageView()
        configureLogoutButton()
        configureNameLabel()
        configureLoginNameLabel()
        configureDescriptionLabel()
        updateProfile(profile: profileService.profile)
        profileImageServiceObserve()
    }
    
    // MARK: - Configuration function
    
    func configureAvatarImageView() {
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.image = UIImage(named: "") ?? UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.tintColor = .ypGray
        avatarImageView.layer.cornerRadius = avatarImageView.frame.size.width / 2
        avatarImageView.clipsToBounds = true
        view.addSubview(avatarImageView)
        
        NSLayoutConstraint.activate([
            avatarImageView.heightAnchor.constraint(equalToConstant: 70),
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            avatarImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32)
        ])
        
    }
    
    func  configureLogoutButton() {
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.setImage(UIImage(named: "exit") ?? UIImage(systemName: "ipad.and.arrow.forward")!, for: .normal)
        logoutButton.addTarget(self,
                               action: #selector(Self.didTapLogoutButton),
                               for: .touchUpInside)
        logoutButton.tintColor = .ypRed
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            logoutButton.heightAnchor.constraint(equalToConstant: 24),
            logoutButton.widthAnchor.constraint(equalToConstant: 24),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            logoutButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 55)
        ])
    }
    
    func configureNameLabel() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = ""
        nameLabel.textColor = .ypWhite
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        view.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8)
        ])
    }
    
    func configureLoginNameLabel() {
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        loginNameLabel.text = ""
        loginNameLabel.textColor = .ypGray
        loginNameLabel.font = UIFont.systemFont(ofSize: 13, weight: .light)
        view.addSubview(loginNameLabel)
        
        NSLayoutConstraint.activate([
            loginNameLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            loginNameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8)
        ])
    }
    
    func configureDescriptionLabel() {
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = ""
        descriptionLabel.textColor = .ypWhite
        descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .light)
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8)
        ])
    }
    
    func updateProfile(profile: Profile?) {
        guard let profile = profile else { return }
        self.nameLabel.text = profile.name
        self.loginNameLabel.text = profile.loginName
        self.descriptionLabel.text = profile.bio
    }
    
    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: profileImageURL) else { return }
        
        let cache = ImageCache.default
        cache.clearMemoryCache()
        cache.clearDiskCache()
        
        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        avatarImageView.kf.indicatorType = .activity
        avatarImageView.kf.setImage(with: url,
                                    placeholder: UIImage(named: "placeholder.jpeg"),
                                    options: [.processor(processor)])
        
    }
    
    func profileImageServiceObserve() {
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.updateAvatar()
        }
        updateAvatar()
    }
    
}


