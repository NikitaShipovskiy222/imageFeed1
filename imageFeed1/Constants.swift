
import Foundation

enum Constants {
    static let accessKey = "_ZT_Gb7ZjRKinn2vJy2VaNsf4c6alNo0JwDC8MURW3k"
    static let secretKey = "ivsNW9zyO53Gs_OT6ZRte9B-j2FoIEE2ankpsqWOkyk"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    static let defaultBaseURL = "https://api.unsplash.com/"
}

enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
    static let urlComponentsPath = "/oauth/authorize/native"
}

enum OAuthConstants {
    static let baseURL = "https://unsplash.com"
}

enum ProfileConstants {
    static let urlProfilePath = "https://api.unsplash.com/me"
}
