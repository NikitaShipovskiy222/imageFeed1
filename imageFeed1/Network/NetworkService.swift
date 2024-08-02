

import Foundation

// MARK: - Protocol
protocol NetworkService {
    associatedtype Model: Decodable
    
    func makeRequest(parameters: [String: String], method: String, url: String) -> URLRequest?
    func parse(data: Data) -> Model?
    func fetch(parameters: [String: String], method: String, url: String, completion: @escaping (Result<Model, Error>) -> Void)
}

// MARK: - Extension
extension NetworkService {
    func fetch(parameters: [String: String], method: String, url: String, completion: @escaping (Result<Model, Error>) -> Void) {
        
        let fulfillCompletionOnTheMainThread: (Result<Model, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        guard let request = makeRequest(parameters: parameters, method: method, url: url) else {
            fulfillCompletionOnTheMainThread(.failure(NetworkError.unableToConstructURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                fulfillCompletionOnTheMainThread(.failure(error))
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200, let data else {
                fulfillCompletionOnTheMainThread(.failure(NetworkError.unknownError))
                return
            }
            
            if let model = self.parse(data: data) {
                fulfillCompletionOnTheMainThread(.success(model))
            } else {
                let error = NetworkErrorHandler.handleErrorResponse(statusCode: response.statusCode)
                fulfillCompletionOnTheMainThread(.failure(error))
            }
        }
        task.resume()
    }
}
