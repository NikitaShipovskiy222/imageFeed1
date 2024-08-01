//
//  AuthService.swift
//  ImageFeed
//
//  Created by Konstantin Lyashenko on 04.06.2024.
//


import Foundation
import WebKit
// MARK: - protocol
protocol AuthServiceDelegate: AnyObject {
    func authService(_ authService: AuthService, didAuthenticateWithCode code: String)
    func authServiceDidCancel(_ authService: AuthService)
    func authService(_ authService: AuthService, didFailWithError error: Error)
}

// MARK: - object
final class AuthService: NSObject {
    weak var delegate: AuthServiceDelegate?
    private let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
        super.init()
        self.webView.navigationDelegate = self
    }
    
    private func authURL() -> String? {
        var urlComponents = URLComponents(string: Constants.unsplashAuthorizeURLString)
        urlComponents?.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        return urlComponents?.url?.absoluteString
    }
    
    func loadAuthView() {
        guard let urlString = authURL(), let url = URL(string: urlString) else {
            delegate?.authService(self, didFailWithError: NetworkError.invalidURLString)
            return
        }
        print("Загружаем URL: \(url.absoluteString)")
        
        let request = URLRequest(url: url)
        DispatchQueue.main.async {
            self.webView.load(request)
        }
    }
    
    private func showErrorAlert(with message: String) {
        delegate?.authService(self, didFailWithError: NSError(domain: "",
                                                              code: 0,
                                                              userInfo: [NSLocalizedDescriptionKey: message]))
    }
}

// MARK: - WKNavigationDelegate
extension AuthService: WKNavigationDelegate {
    func webView(_ webView: WKWebView, 
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let code = code(from: navigationAction) {
            self.delegate?.authService(self, didAuthenticateWithCode: code)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showErrorAlert(with: NetworkErrorHandler.errorMessage(from: error))
        print("Ошибка при загрузке: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Загрузка завершена")
    }
}

// MARK: - code method
extension AuthService {
    private func code(from navigationAction: WKNavigationAction) -> String? {
        if let url = navigationAction.request.url,
            let urlComponents = URLComponents(string: url.absoluteString),
            urlComponents.path == Constants.authRedirectPath,
            let items = urlComponents.queryItems,
            let codeItem = items.first(where: { $0.name == "code" }) {
            return codeItem.value
        } else {
            return nil
        }
    }
}
