

import Foundation

enum APIEndpoints {
    enum OAuth {
        static let token = "https://unsplash.com/oauth/token"
    }

    enum Profile {
        static func profile(username: String) -> String {
            return "https://api.unsplash.com/users/\(username)"
        }
        static let me = "https://api.unsplash.com/me"
    }
    
    enum Photos {
        static let photos = "https://api.unsplash.com/photos"
    }
}

enum Constants {
    static var accessKey: String {
        return KeychainService.shared.get(valueFor: "accessKey") ?? ""
    }
    static var secretKey: String {
        return KeychainService.shared.get(valueFor: "secretKey") ?? ""
    }
    static var redirectURI: String {
        return KeychainService.shared.get(valueFor: "redirectURI") ?? ""
    }
    static let accessScope = "public+read_user+write_likes"
    static let defaultBaseURL = URL(string: "https://api.unsplash.com")!
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
    static let authRedirectPath = "/oauth/authorize/native"
}
