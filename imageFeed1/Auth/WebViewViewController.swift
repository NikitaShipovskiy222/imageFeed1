//
//  WebViewViewController.swift
//  ImageFeed
//
//  Created by Konstantin Lyashenko on 31.05.2024.
//

import UIKit
import WebKit

// MARK: - protocol
protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
    func webViewViewController(_ vc: WebViewViewController, didFailWithError error: Error)
}

// MARK: - UIViewController
class WebViewViewController: UIViewController {
    
    weak var delegate: WebViewViewControllerDelegate?
    
    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .ypBlack
        return progressView
    }()
    
    private lazy var backButton: UIBarButtonItem = {
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(backButtonPressed))
        backButton.tintColor = .ypBlack
        return backButton
    }()
    
    private var authService: AuthService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        setupUI()
        authService = AuthService(webView: webView)
        authService?.delegate = self
        updateProgress()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        authService?.loadAuthView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            updateProgress()
        } else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
        }
    }

    private func updateProgress() {
        progressView.progress = Float(webView.estimatedProgress)
        progressView.isHidden = fabs(webView.estimatedProgress - 1.0) <= 0.0001
    }
    
    private func setupUI() {
        configureBackButton()
        view.addSubview(progressView)
        view.addSubview(webView)
        setupConstraints()
    }
    
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = backButton
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc private func backButtonPressed() {
        let alert = UIAlertController(title: "Выход из авторизации",
                                      message: "Вы уверены, что хотите покинуть страницу авторизации?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Выход", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.delegate?.webViewViewControllerDidCancel(self)
        })
        present(alert, animated: true)
    }
}

// MARK: - AuthServiceDelegate
extension WebViewViewController: AuthServiceDelegate {
    func authService(_ authService: AuthService, didAuthenticateWithCode code: String) {
        delegate?.webViewViewController(self, didAuthenticateWithCode: code)
    }

    func authServiceDidCancel(_ authService: AuthService) {
        delegate?.webViewViewControllerDidCancel(self)
    }

    func authService(_ authService: AuthService, didFailWithError error: Error) {
        delegate?.webViewViewController(self, didFailWithError: error)
    }
}
