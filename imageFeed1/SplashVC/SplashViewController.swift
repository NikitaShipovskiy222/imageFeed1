
import UIKit

// MARK: - Object
final class SplashViewController: UIViewController {
    
    private let profileService = ProfileService.shared
    private let storage = OAuth2TokenStorage.shared
    private let profileImageService = ProfileImageService.shared
    private let imagesListService = ImagesListService.shared

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAuthorization()
    }
    
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else {
            Logger.shared.log(.error,
                              message: "SplashViewController: неверная конфигурация window",
                              metadata: ["❌": ""])
            return
        }
        
        let tabBarController = createTabBarController()
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }
    
    private func showAuthViewController() {
        let authViewController = AuthViewController()
        authViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: authViewController)
        
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }
    
    private func createTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()

        let imagesListViewController = ImagesListViewController()
        let profileViewController = ProfileViewController()
        
        imagesListViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "square.stack.fill"), tag: 0)
        profileViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "person.crop.circle.fill"), tag: 1)
        
        UINavigationBar.appearance().barTintColor = .ypBlack
        UINavigationBar.appearance().tintColor = .ypWhite
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ypWhite]
        
        UITabBar.appearance().barTintColor = .ypBlack
        UITabBar.appearance().tintColor = .ypWhite
        
        let imagesNavigationController = UINavigationController(rootViewController: imagesListViewController)
        let profileNavigationController = UINavigationController(rootViewController: profileViewController)
        
        tabBarController.viewControllers = [
            imagesNavigationController,
            profileNavigationController
        ]
        return tabBarController
    }
}

// MARK: - Authorization
private extension SplashViewController {
    
    private func checkAuthorization() {
        if let token = storage.token {
            if !profileService.isProfileLoaded {
                fetchProfile(token)
            } else {
                switchToTabBarController()
            }
        } else {
            showAuthViewController()
        }
    }
}

// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    
    func fetchProfile(_ token: String) {
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    UIBlockingProgressHUD.dismiss()
                    return
                }
                
                switch result {
                case .success(let profile):
                    self.profileImageService.fetchProfileImageURL(username: profile.userName, token: token) { imageResult in
                        DispatchQueue.main.async {
                            UIBlockingProgressHUD.dismiss()
                            switch imageResult {
                            case .success(_):
                                self.switchToTabBarController()
                            case .failure(let error):
                                _ = NetworkErrorHandler.errorMessage(from: error)
                                self.showAuthViewController()
                            }
                        }
                    }
                case .failure(let error):
                    UIBlockingProgressHUD.dismiss()
                    _ = NetworkErrorHandler.errorMessage(from: error)
                    self.showAuthViewController()
                }
            }
        }
    }
    
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true)
    }
}
