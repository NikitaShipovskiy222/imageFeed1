

import UIKit

final class SingleImageViewController: UIViewController {
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        scrollView.delegate = self
        scrollView.backgroundColor = .ypBlack
        return scrollView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .ypBlack
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        button.tintColor = .ypWhite
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        button.tintColor = .ypWhite
        button.layer.cornerRadius = 25
        button.backgroundColor = .ypBlack
        button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        setupViews()
    }
    
    private func setupViews() {
        [scrollView, backButton, shareButton].forEach {
            view.addSubview($0)
        }
        scrollView.addSubview(imageView)
        
        [scrollView,
         imageView,
         backButton,
         shareButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            
            backButton.widthAnchor.constraint(equalToConstant: 24),
            backButton.heightAnchor.constraint(equalToConstant: 24),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            
            shareButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            shareButton.widthAnchor.constraint(equalToConstant: 50),
            shareButton.heightAnchor.constraint(equalToConstant: 50),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 17)
        ])
    }
}

// MARK: - Setting scrollView
private extension SingleImageViewController {
    private func rescaleAndCenterImageInScrollView() {
        guard let image = imageView.image else { return }

        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        scrollView.setZoomScale(scale, animated: false)
        
        let imageViewSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let horizontalPadding = max(0, (visibleRectSize.width - imageViewSize.width) / 2)
        let verticalPadding = max(0, (visibleRectSize.height - imageViewSize.height) / 2)
        scrollView.contentInset = UIEdgeInsets(top: verticalPadding,
                                               left: horizontalPadding,
                                               bottom: verticalPadding,
                                               right: horizontalPadding)
    }
}

// MARK: - Button Action
private extension SingleImageViewController {
    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Configure Image
extension SingleImageViewController {
    func configure(withImageURL imageURL: URL) {
        imageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        imageView.alpha = 0
        
        DispatchQueue.main.async {
            UIBlockingProgressHUD.show() // тут анимация показалась и и счезла, не вижу смысла ослаблять ссылку
        }
        
        imageView.kf.setImage(with: imageURL) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(_):
                UIBlockingProgressHUD.dismiss()
                
                UIView.animate(withDuration: 0.3,
                               delay: 0,
                               options: [.curveEaseOut],
                               animations: {
                    self.imageView.transform = CGAffineTransform.identity
                    self.imageView.alpha = 1
                    self.rescaleAndCenterImageInScrollView()
                })
            case .failure(let error):
                UIBlockingProgressHUD.dismiss()
                let errorMessage = NetworkErrorHandler.errorMessage(from: error)
                print("Ошибка загрузки изображения: \(errorMessage)")
            }
        }
    }
}

// MARK: - UIScrollViewDelegate
extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

// MARK: - Share
private extension SingleImageViewController {
    @objc private func shareButtonTapped() {
        guard let image = imageView.image else { return }
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        activityViewController.completionWithItemsHandler = { [weak self] _, success, _, error in
            guard self != nil else { return }
            
            if let error = error {
                let errorMessage = NetworkErrorHandler.errorMessage(from: error)
                Logger.shared.log(.error,
                                  message: "ImagesListService: Не удалось расшарить изображения",
                                  metadata: ["❌": errorMessage])
            } else if success {
                Logger.shared.log(.debug,
                                  message: "SingleImageViewController: Изображения успешно расшарено",
                                  metadata: ["✅": ""])
            } else {
                Logger.shared.log(.debug,
                                  message: "SingleImageViewController: Sharing отменен",
                                  metadata: ["✅": ""])
            }
        }
        DispatchQueue.main.async {
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
}
