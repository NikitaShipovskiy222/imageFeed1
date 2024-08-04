

import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
}

enum AuthServiceError: Error {
    case invalidRequest
}

enum ProfileServiceError: Error {
    case invalidRequest
}
