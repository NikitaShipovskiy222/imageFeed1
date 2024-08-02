
import Foundation

// MARK: - protocol
protocol NetworkErrorProtocol {
    static func errorMessage(from error: Error) -> String
    static func handleErrorResponse(statusCode: Int) -> NetworkError
}

enum NetworkError: Error {
    case invalidURLString
    case unableToConstructURL
    case noInternetConnection
    case requestTimedOut
    case emptyData
    case tooManyRequests
    case unknownError
    case serviceUnavailable
    case errorFetchingAccessToken
    case unauthorized
    case notFound
}

struct NetworkErrorHandler: NetworkErrorProtocol {
    
    static func errorMessage(from error: Error) -> String {
        var errorMessage = "Произошла ошибка при загрузке данных"
        
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURLString:
                errorMessage = "Неверный URL"
            case .unableToConstructURL:
                errorMessage = "Невозможно создать URL"
            case .noInternetConnection:
                errorMessage = "Отсутствует подключение к интернету"
            case .requestTimedOut:
                errorMessage = "Превышено время ожидания ответа от сервера"
            case .emptyData:
                errorMessage = "Данные не были получены"
            case .tooManyRequests:
                errorMessage = "Вы превысили лимит запросов к API. Попробуйте снова позже."
            case .unknownError:
                errorMessage = "Неизвестная ошибка"
            case .serviceUnavailable:
                errorMessage = "Сервис недоступен. Попробуйте снова позже."
            case .errorFetchingAccessToken:
                errorMessage = "Ошибка получения токена доступа"
            case .unauthorized:
                errorMessage = "Недостаточно прав"
            case .notFound:
                errorMessage = "Запрашиаемый ресурс не существует"
            }
        }
        return errorMessage
    }
    
    static func handleErrorResponse(statusCode: Int) -> NetworkError {
        switch statusCode {
        case 400:
            return .invalidURLString
        case 401:
            return .errorFetchingAccessToken
        case 403:
            return .unauthorized
        case 404:
            return .notFound
        case 422:
            return .unknownError
        case 429:
            return .tooManyRequests
        case 500, 503:
            return .serviceUnavailable
        default:
            return .unknownError
        }
    }
}

