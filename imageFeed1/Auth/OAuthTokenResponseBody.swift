//
//  OAuthTokenResponseBody.swift
//  ImageFeed
//
//  Created by Konstantin Lyashenko on 05.06.2024.
//

import Foundation
// MARK: - model
struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case createdAt = "created_at"
    }
}
