

import UIKit

protocol ProfileViewControllerProtocol: AnyObject {
    func showProfileDetails(profile: Profile)
    func showLoading()
    func hideLoading()
    func updateProfileImage(with image: UIImage)
}

// MARK: - Object
final class ProfileViewController: UIViewController {
    
    private var presenter: ProfilePresenterProtocol?
    lazy var profileLoadingView = ProfileLoadingView()
    
    lazy var profileImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "person.crop.circle.fill")
        imageView.tintColor = .ypGray
        imageView.layer.cornerRadius = 35
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var exitButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = "logoutButton"
        button.setImage(UIImage(systemName: "ipad.and.arrow.forward"), for: .normal)
        button.tintColor = .ypRed
        button.addTarget(self, action: #selector(exitButtonPressed), for: .touchUpInside)
        return button
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypWhite
        label.font = UIFont.boldSystemFont(ofSize: 23)
        return label
    }()
    
    lazy var loginNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypGray
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypWhite
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [profileImage,
                                                       exitButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        return stackView
    }()
    
    private lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [horizontalStackView,
                                                       nameLabel,
                                                       loginNameLabel,
                                                       descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        setupUI()
        setupConstraints()
        
        presenter?.viewDidLoad()
    }
    
    func configure(_ presenter: ProfilePresenterProtocol) {
        self.presenter = presenter
        self.presenter?.view = self
    }
    
    private func setupUI() {
        view.addSubview(profileLoadingView)
        profileLoadingView.frame = view.bounds
        profileLoadingView.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]
    }
    
    private func setupConstraints() {
        [profileImage,
         exitButton,
         nameLabel,
         loginNameLabel,
         descriptionLabel,
         verticalStackView,
         profileLoadingView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        view.addSubview(verticalStackView)
        
        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                   constant: 16),
            verticalStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                       constant: 16),
            verticalStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                        constant: -16),
            
            profileImage.widthAnchor.constraint(equalToConstant: 70),
            profileImage.heightAnchor.constraint(equalTo: profileImage.widthAnchor),
            
            exitButton.widthAnchor.constraint(equalToConstant: 42),
            exitButton.heightAnchor.constraint(equalTo: exitButton.widthAnchor),
            
            profileLoadingView.topAnchor.constraint(
                equalTo: view.topAnchor),
            profileLoadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileLoadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileLoadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        profileImage.layer.cornerRadius = 35
        profileImage.layer.masksToBounds = true
    }
}

// MARK: - ProfileViewControllerProtocol
extension ProfileViewController: ProfileViewControllerProtocol {
    func showLoading() {
        profileLoadingView.startAnimating()
    }
    
    func hideLoading() {
        profileLoadingView.removeFromSuperview()
    }
    
    func showProfileDetails(profile: Profile) {
        nameLabel.text = profile.name
        loginNameLabel.text = profile.loginName
        descriptionLabel.text = profile.bio
    }
    
    func updateProfileImage(with image: UIImage) {
        profileImage.image = image
    }
}

// MARK: - Button Action
extension ProfileViewController {
    @objc func exitButtonPressed() {
        presenter?.exitButtonPressed()
    }
}

// MARK: - AlertPresenterDelegate
extension ProfileViewController: AlertPresenterDelegate {
    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true)
    }
}
