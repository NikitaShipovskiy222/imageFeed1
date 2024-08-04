//
//
//
//import Foundation
//import WebKit
//// MARK: - protocol
//protocol AuthServiceDelegate: AnyObject {
//    func authService(_ authService: AuthService, didAuthenticateWithCode code: String)
//    func authServiceDidCancel(_ authService: AuthService)
//    func authService(_ authService: AuthService, didFailWithError error: Error)
//}
//
//// MARK: - object
//final class AuthService: NSObject {
//    weak var delegate: AuthServiceDelegate?
//    private let webView: WKWebView
//
//    init(webView: WKWebView) {
//        self.webView = webView
//        super.init()
//        self.webView.navigationDelegate = self
//    }
//    
//    private func authURL() -> String? {
//        var urlComponents = URLComponents(string: Constants.unsplashAuthorizeURLString)
//        urlComponents?.queryItems = [
//            URLQueryItem(name: "client_id", value: Constants.accessKey),
//            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
//            URLQueryItem(name: "response_type", value: "code"),
//            URLQueryItem(name: "scope", value: Constants.accessScope)
//        ]
//        return urlComponents?.url?.absoluteString
//    }
//    
//    func loadAuthView() {
//        guard let urlString = authURL(), let url = URL(string: urlString) else {
//            delegate?.authService(self, didFailWithError: NetworkError.invalidURLString)
//            Logger.shared.log(.error,
//                              message: "AuthService: Неверная строка URL",
//                              metadata: ["❌": ""])
//            return
//        }
//        
//        let request = URLRequest(url: url)
//        
//        Logger.shared.log(.debug,
//                          message: "AuthService: Запрос создан:",
//                          metadata: ["✅": "\(request)"])
//        
//        DispatchQueue.main.async { [weak self] in
//            guard let self else { return }
//            self.webView.load(request)
//        }
//    }
//    
//    private func showErrorAlert(with message: String) {
//        delegate?.authService(self, didFailWithError: NSError(domain: "",
//                                                              code: 0,
//                                                              userInfo: [NSLocalizedDescriptionKey: message]))
//    }
//}
//
//// MARK: - WKNavigationDelegate
//extension AuthService: WKNavigationDelegate {
//    func webView(_ webView: WKWebView,
//                 decidePolicyFor navigationAction: WKNavigationAction,
//                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        if let code = code(from: navigationAction) {
//            self.delegate?.authService(self, didAuthenticateWithCode: code)
//            decisionHandler(.cancel)
//        } else {
//            decisionHandler(.allow)
//        }
//    }
//
//    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//        let errorMessage = NetworkErrorHandler.errorMessage(from: error)
//        showErrorAlert(with: errorMessage)
//        Logger.shared.log(.error,
//                          message: "AuthService: Ошибка при загрузке данных WebView",
//                          metadata: ["❌": errorMessage])
//    }
//    
//    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        Logger.shared.log(.debug,
//                          message: "AuthService: Загрузка завершена:",
//                          metadata: ["✅": ""])
//    }
//}
//
//// MARK: - code method
//extension AuthService {
//    private func code(from navigationAction: WKNavigationAction) -> String? {
//        if let url = navigationAction.request.url,
//            let urlComponents = URLComponents(string: url.absoluteString),
//            urlComponents.path == Constants.authRedirectPath,
//            let items = urlComponents.queryItems,
//            let codeItem = items.first(where: { $0.name == "code" }) {
//            return codeItem.value
//        } else {
//            return nil
//        }
//    }
//}
