

import UIKit
import SkeletonView

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    
    var photoId: String?
    var isLiked: Bool = false {
        didSet {
            likeButton.tintColor = isLiked ? .ypRed : .ypWhite.withAlphaComponent(0.5)
        }
    }
    var likeButtonAction: ((String, Bool) -> Void)?
    
    private lazy var customContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .ypBlack
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var customImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .ypBlack
        imageView.isSkeletonable = true
        return imageView
    }()
    
    private lazy var customTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .ypWhite
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var likeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .ypGray
        let heartImage = UIImage(systemName: "heart.fill")?.withRenderingMode(.alwaysTemplate)
        button.setImage(heartImage, for: .normal)
        button.addTarget(self, action: #selector(likeButtonPressed), for: .touchUpInside)
        return button
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupViews()
        configureSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        customImageView.kf.cancelDownloadTask()
    }
    
    private func setupViews() {
        contentView.addSubview(customContentView)
        [customImageView, likeButton, customTextLabel].forEach {
            customContentView.addSubview($0)
        }
        addGradientView()
    }
    
    private func addGradientView() {
        let gradientView = UIView(frame: CGRect(
            x: 0.0,
            y: customContentView.frame.height - 30.0,
            width: customImageView.bounds.width,
            height: 30.0)
        )
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [UIColor.clear.cgColor,
                                UIColor.ypBlack.withAlphaComponent(0.4).cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientView.layer.addSublayer(gradientLayer)
        customContentView.addSubview(gradientView)
    }
    
    private func configureSubviews() {
        NSLayoutConstraint.activate([
            customContentView.topAnchor.constraint(equalTo: topAnchor),
            customContentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            customContentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            customContentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            customImageView.topAnchor.constraint(equalTo: customContentView.topAnchor),
            customImageView.bottomAnchor.constraint(equalTo: customContentView.bottomAnchor),
            customImageView.leadingAnchor.constraint(equalTo: customContentView.leadingAnchor),
            customImageView.trailingAnchor.constraint(equalTo: customContentView.trailingAnchor),
            
            customTextLabel.heightAnchor.constraint(equalToConstant: 18),
            customTextLabel.bottomAnchor.constraint(equalTo: customContentView.bottomAnchor, constant: -8),
            customTextLabel.leadingAnchor.constraint(equalTo: customContentView.leadingAnchor, constant: 8),
            customTextLabel.trailingAnchor.constraint(equalTo: customContentView.trailingAnchor),
            
            likeButton.topAnchor.constraint(equalTo: customContentView.topAnchor),
            likeButton.trailingAnchor.constraint(equalTo: customContentView.trailingAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 42),
            likeButton.heightAnchor.constraint(equalToConstant: 42)
        ])
    }
}

// MARK: - Button Action
private extension ImagesListCell {
  @objc func likeButtonPressed() {
    guard let photoId = photoId else { return }
    
    isLiked.toggle()
    likeButtonAction?(photoId, isLiked)
  }
}


// MARK: - SkeletonView
private extension ImagesListCell {
    private func showSkeletons() {
        DispatchQueue.main.async { // анимация показалась и исчезла, не вижу смысла ослаблять ссылку
            self.customImageView.showAnimatedGradientSkeleton(usingGradient: .init(baseColor: .darkGray))
        }
    }

    private func hideSkeletons() {
        DispatchQueue.main.async { // аналогично
            self.customImageView.hideSkeleton()
            self.customImageView.isSkeletonable = false
        }
    }
}

// MARK: - Configure Image
extension ImagesListCell {
    func configure(withImageURL imageURL: URL?, text: String, isLiked: Bool, photoId: String) {
        
        self.photoId = photoId
        self.isLiked = isLiked
        
        customImageView.contentMode = .center
        showSkeletons()
        
        if let imageURL = imageURL {
            customImageView.kf.setImage(with: imageURL,
                                        placeholder: UIImage(named: "Stub"),
                                        options: [
                                            .transition(.fade(0.1)),
                                            .cacheOriginalImage]) { [weak self] result in
                                                guard let self else { return }
                                                switch result {
                                                case .success(_):
                                                    self.customImageView.contentMode = .scaleAspectFill
                                                    hideSkeletons()
                                                case .failure(_):
                                                    break
                                                }
                                            }
        } else {
            customImageView.image = nil
        }
        customTextLabel.text = text
    }
}
