//
//  Constants.swift
//  ImageFeed
//
//  Created by Konstantin Lyashenko on 30.05.2024.
//

import Foundation

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

