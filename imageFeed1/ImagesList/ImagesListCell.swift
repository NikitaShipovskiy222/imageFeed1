//
//  ImageTableViewCell.swift
//  ImageFeed
//
//  Created by Konstantin Lyashenko on 07.05.2024.
//

import UIKit

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    
    private lazy var customContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .ypBlack
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var image: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .ypBlack
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
    
    private func setupViews() {
        contentView.addSubview(customContentView)
        customContentView.addSubview(image)
        customContentView.addSubview(likeButton)
        customContentView.addSubview(customTextLabel)
        addGradientView()
    }
    
    private func addGradientView() {
        let gradientView = UIView(frame: CGRect(x: 0.0, y: customContentView.frame.height - 30.0, width: image.bounds.width, height: 30.0))
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.ypBlack.withAlphaComponent(0.4).cgColor]
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
            
            image.topAnchor.constraint(equalTo: customContentView.topAnchor),
            image.bottomAnchor.constraint(equalTo: customContentView.bottomAnchor),
            image.leadingAnchor.constraint(equalTo: customContentView.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: customContentView.trailingAnchor),
            
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
    
    @objc func likeButtonPressed() {
        likeButton.tintColor = likeButton.tintColor == .ypRed ? .ypWhite.withAlphaComponent(0.5) : .ypRed
    }
    
    func configure(withImage image: UIImage?, text: String, isLiked: Bool, tintColor: UIColor) {
        self.image.image = image
        customTextLabel.text = text
    }
}
