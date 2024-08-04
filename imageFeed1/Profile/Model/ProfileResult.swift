
import UIKit

struct ProfileResult: Codable {
    enum CodingKeys: String, CodingKey {
        case userName = "username"
        case firstName = "first_name"
        case lastName = "last_name"
        case bio = "bio"
    }
    let userName: String
    let firstName: String?
    let lastName: String?
    let bio: String?
}

struct Profile {
    let userName: String
    let name: String
    let loginName: String
    let bio: String?
    
    init(result: ProfileResult) {
        self.userName = result.userName
        self.name = "\(result.firstName ?? "") \(result.lastName ?? "")"
        self.loginName = "@\(result.userName)"
        self.bio = result.bio
    }
    
}
