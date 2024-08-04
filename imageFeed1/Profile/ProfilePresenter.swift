//
//import UIKit
//// MARK: - Protocols
//protocol ProfilePresenterProtocol {
//    var view: ProfileViewControllerProtocol? { get set }
//    func viewDidLoad()
//    func exitButtonPressed()
//    func tryShowProfileDetails()
//    func updateProfileImage(with url: String)
//}
//
//// MARK: - Object
//final class ProfilePresenter {
//   
//    weak var view: ProfileViewControllerProtocol?
//    private var profileImageServiceObserver: NSObjectProtocol?
//    private var alertPresenter = AlertPresentor()
//    
//    init(view: ProfileViewControllerProtocol) {
//        self.view = view
//    }
//    
//    func viewDidLoad() {
//        view?.showLoading()
//        addObserver()
//        tryShowProfileDetails()
//    }
//    
//    private func addObserver() {
//        profileImageServiceObserver = NotificationCenter.default.addObserver(forName: ProfileImageService.didChangeNotification,
//                                                                             object: nil,
//                                                                             queue: .main,
//                                                                             using: { [weak self] notification in
//            guard let self else { return }
//            
//            if let userInfo = notification.userInfo, let profileImageURL = userInfo["URL"] as? String {
//                updateProfileImage(with: profileImageURL)
//            }
//        })
//        
//        if let profileImageURL = ProfileImageService.shared.avatarURL {
//            updateProfileImage(with: profileImageURL)
//        }
//    }
//}
//
//// MARK: - ProfilePresenterProtocol
//extension ProfilePresenter: ProfilePresenterProtocol {
//    
//    func exitButtonPressed() {
//        let alertModel = AlertModel(
//            title: "Пока, пока!",
//            message: "Уверены что хотите выйти?",
//            buttons: [
//                AlertButton(title: "Нет", style: .default, identifier: nil, handler: nil),
//                AlertButton(title: "Да", style: .cancel, identifier: "Yes", handler: {
//                    ProfileLogoutService.shared.logout()
//                })
//            ],
//            context: .back
//        )
//        AlertPresentor.(with: alertModel, delegate: view as? AlertPresenterDelegate)
//    }
//    
//    func tryShowProfileDetails() {
//        let profileService = ProfileService.shared
//        if let profile = profileService.profile {
//            view?.hideLoading()
//            view?.showProfileDetails(profile: profile)
//        } else {
//            view?.showLoading()
//        }
//    }
//    
//    func updateProfileImage(with url: String) {
//        guard let url = URL(string: url) else { return }
//        
//        view?.showLoading()
//        
//        let imageView = UIImageView()
//        imageView.kf.indicatorType = .activity
//        imageView.kf.setImage(with: url,
//                              placeholder: UIImage(systemName: "person.crop.circle.fill"),
//                              options: [.transition(.fade(0.2))]) { [weak self] result in
//            guard let self else { return }
//            switch result {
//            case .success(let value):
//                self.view?.updateProfileImage(with: value.image)
//                self.view?.hideLoading()
//            case .failure(let error):
//                let errorMessage = NetworkErrorHandler.errorMessage(from: error)
//                Logger.shared.log(.error,
//                                  message: "ProfilePresenter: Не удалось загрузить Image",
//                                  metadata: ["❌": errorMessage])
//                self.view?.hideLoading()
//            }
//        }
//    }
//}
