

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if KeychainService.shared.get(valueFor: "accessKey") == nil {
            _ = KeychainService.shared.set(value: "YDB9YmrpeX5TFK7woqynOGi5hBWLuoBG8bJ9kxaOLb8", for: "accessKey")
        }
        if KeychainService.shared.get(valueFor: "secretKey") == nil {
            _ = KeychainService.shared.set(value: "oEgPi3ZUXExKMhNxwpw0eAKRWBCyfRjh17NuYONkMEs", for: "secretKey")
        }
        if KeychainService.shared.get(valueFor: "redirectURI") == nil {
            _ = KeychainService.shared.set(value: "urn:ietf:wg:oauth:2.0:oob", for: "redirectURI")
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

