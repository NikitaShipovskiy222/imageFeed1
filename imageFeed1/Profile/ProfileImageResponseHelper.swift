//
//
//import Foundation
//
//// MARK: - Protocol
//protocol ProfileImageResponseHelperProtocol {
//    static func parseUserResult(from data: Data) -> UserResult?
//    static func handleFetchError(_ error: Error, completion: @escaping (Result<String, Error>) -> Void)
//}
//
//// MARK: - Object
//final class ProfileImageResponseHelper: ProfileImageResponseHelperProtocol {
//    static func parseUserResult(from data: Data) -> UserResult? {
//        do {
//            let userResult = try JSONDecoder().decode(UserResult.self, from: data)
//            Logger.shared.log(.debug,
//                              message: "ProfileImageResponseHelper: Данные успешно обработаны",
//                              metadata: ["✅": ""])
//            return userResult
//        } catch {
//            let errorMessage = NetworkErrorHandler.errorMessage(from: error)
//            Logger.shared.log(.error,
//                              message: "ProfileImageResponseHelper: Ошибка парсинга данных",
//                              metadata: ["❌": errorMessage])
//            return nil
//        }
//    }
//
//    static func handleFetchError(_ error: Error, completion: @escaping (Result<String, Error>) -> Void) {
//        let errorMessage = NetworkErrorHandler.errorMessage(from: error)
//        Logger.shared.log(.error,
//                          message: "ProfileImageResponseHelper: Ошибка получения данных",
//                          metadata: ["❌": errorMessage])
//        completion(.failure(error))
//    }
//}
