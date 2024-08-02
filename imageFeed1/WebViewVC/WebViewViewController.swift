

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
    
    private var authService: AuthService?
    private var estimatedProgressObservation: NSKeyValueObservation?
    
    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        return webView
    }()
    
    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
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
        addObserver()
    }
    
    private func setupUI() {
        [progressView, webView].forEach {
            view.addSubview($0)
        }
        configureBackButton()
        setupConstraints()
    }
    
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = backButton
    }
    
    private func setupConstraints() {
        [webView, progressView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
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
}

// MARK: - Update Progress
private extension WebViewViewController {
    
    private func addObserver() {
        estimatedProgressObservation = webView.observe(\.estimatedProgress, changeHandler: { [weak self] _, _ in
            guard let self else { return }
            
            self.updateProgress()
        })
        authService?.loadAuthView()
    }
    
    private func updateProgress() {
        progressView.progress = Float(webView.estimatedProgress)
        progressView.isHidden = fabs(webView.estimatedProgress - 1.0) <= 0.0001
    }
}

// MARK: - Button Action
private extension WebViewViewController {
    
    @objc private func backButtonPressed() {
        let alertModel = AlertModel(
            title: "Выход из авторизации",
            message: "Вы уверены, что хотите покинуть страницу авторизации?",
            buttons: [
                AlertButton(title: "Отмена", style: .cancel, handler: nil),
                AlertButton(title: "Выход", style: .destructive, handler: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.webViewViewControllerDidCancel(self)
                })
            ],
            context: .back
        )
        AlertPresenter.showAlert(with: alertModel, delegate: self)
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
        let alertModel = AlertModel(
            title: "Ошибка",
            message: NetworkErrorHandler.errorMessage(from: error),
            buttons: [AlertButton(title: "OK", style: .cancel, handler: nil)],
            context: .error
        )
        AlertPresenter.showAlert(with: alertModel, delegate: self)
    }
}
// MARK: - AlertPresenterDelegate
extension WebViewViewController: AlertPresenterDelegate {
    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true, completion: nil)
    }
}
