

import Foundation

import WebKit

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    
    private init() { }
    
    func logout() {
        cleanCookies()
        clearLocalData()
        switchToSplashViewController()
    }
    
    private func cleanCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
    
    private func clearLocalData() {
        ProfileService.shared.clearProfileData()
        ProfileImageService.shared.clearProfileImage()
        ImagesListService.shared.clearImagesList()
        OAuth2TokenStorage.shared.logout()
    }
    
    private func switchToSplashViewController() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                Logger.shared.log(.error,
                                  message: "SplashViewController: неверная конфигурация window",
                                  metadata: ["❌": ""])
                return
            }
            let splashViewController = SplashViewController()
            window.rootViewController = splashViewController
            window.makeKeyAndVisible()
        }
    }
}
