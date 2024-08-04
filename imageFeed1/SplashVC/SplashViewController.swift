
import UIKit
import ProgressHUD

class SplashViewController: UIViewController {
    
    // MARK: - View
    
    private let splashImageView = UIImageView()
    
    // MARK: - Properties
    
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let storage = OAuth2TokenStorage()
    private let oAuth2Service = OAuth2Service.shared
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    private let alert = AlertPresentor.shared
    
    // MARK: - Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupLayer()
        if let token = storage.token {
            fetchProfile(token: token)
        } else {
            segueToAuthView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .ypBlack
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - Override
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        if segue.identifier == showAuthenticationScreenSegueIdentifier {
    //            guard
    //                let navigationController = segue.destination as? UINavigationController,
    //                let viewController = navigationController.viewControllers[0] as? AuthViewController
    //            else {
    //                assertionFailure("Failed to prepare for \(showAuthenticationScreenSegueIdentifier)")
    //                return
    //            }
    //            viewController.delegate = self
    //        } else {
    //            super.prepare(for: segue, sender: sender)
    //        }
    //    }
}

// MARK: - Configuration extension

extension SplashViewController {
    
    func setupLayer() {
        view.backgroundColor = .ypBlack
        configurationSplashView()
    }
    
    func configurationSplashView() {
        splashImageView.translatesAutoresizingMaskIntoConstraints = false
        splashImageView.image = UIImage(named: "VectorLaunchScreen")
        view.addSubview(splashImageView)
        
        NSLayoutConstraint.activate([
            splashImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            splashImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            splashImageView.widthAnchor.constraint(equalToConstant: 75),
            splashImageView.heightAnchor.constraint(equalToConstant: 78)
        ])
    }
}

// MARK: - Extension

private extension SplashViewController {
    
    func switchToTabBarVievController() {
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }
        let tabBarController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "TabBarViewController")
        window.rootViewController  = tabBarController
    }
    
    func segueToAuthView() {
        let authViewController = AuthViewController()
        authViewController.delegate = self
        authViewController.modalPresentationStyle = .fullScreen
        self.present(authViewController, animated: true, completion: nil)
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        vc.dismiss(animated: true)
        fetchOAuthToken(code)
    }
    
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true)
    }
    
    private func fetchOAuthToken(_ code: String) {
        UIBlockingProgressHUD.show()
        oAuth2Service.fetchOAuthToken(for: code) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let accessToken):
                self.storage.token = accessToken
                guard let token = storage.token else { return }
                fetchProfile(token: token)
                UIBlockingProgressHUD.dismiss()
            case .failure(let error):
                alert.showNetworkError(with: error)
                break
            }
        }
    }
    
    private func fetchProfile(token: String) {
        profileService.fetchProfile(token) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let profile):
                self.profileImageService.fetchProfileImageURL(username: profile.userName) { result in
                    switch result {
                    case .success(let avatarURL):
                        print(avatarURL)
                    case .failure(let failure):
                        print(failure.localizedDescription)
                        break
                    }
                }
                self.switchToTabBarVievController()
            case .failure(let failure):
                print(failure.localizedDescription)
                break
            }
        }
    }
    
    
    
}
