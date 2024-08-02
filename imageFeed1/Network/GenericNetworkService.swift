

import Foundation

class GenericNetworkService<T: Decodable>: NetworkService {
    typealias Model = T
    
    func makeRequest(parameters: [String: String], method: String, url: String) -> URLRequest? {
        var components = URLComponents(string: url)
        components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let finalURL = components?.url else {
            return nil
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = method
        request.setValue("Bearer \(parameters["token"] ?? "")", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    func parse(data: Data) -> T? {
        do {
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            return decodedObject
        } catch {
            return nil
        }
    }
}
