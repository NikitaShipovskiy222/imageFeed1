

import UIKit
import SkeletonView

final class ProfileLoadingView: UIView {
    
    private lazy var profileImage = buildAnimatedViews()
    private lazy var nameLabel = buildAnimatedViews()
    private lazy var loginNameLabel = buildAnimatedViews()
    private lazy var descriptionLabel = buildAnimatedViews()
    
    private lazy var horizontalStacks: [UIStackView] = {
        let hImageStack = UIStackView()
        let hNameStack = UIStackView()
        let hLoginNameStack = UIStackView()
        let hDescriptionStack = UIStackView()
        let stackArray = [hImageStack, 
                          hNameStack,
                          hLoginNameStack,
                          hDescriptionStack]
        
        stackArray.forEach {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.distribution = .equalSpacing
            $0.isSkeletonable = true
        }
        
        [profileImage, UIView()].forEach {
            hImageStack.addArrangedSubview($0)
        }
        [nameLabel, UIView()].forEach {
            hNameStack.addArrangedSubview($0)
        }
        [loginNameLabel, UIView()].forEach {
            hLoginNameStack.addArrangedSubview($0)
        }
        [descriptionLabel, UIView()].forEach {
            hDescriptionStack.addArrangedSubview($0)
        }
        return stackArray
    }()
    
    private lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: horizontalStacks)
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.isSkeletonable = true
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .ypBlack
        setupConstraints()
        startAnimating()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        addSubview(verticalStackView)
        [profileImage,
         nameLabel,
         loginNameLabel,
         descriptionLabel,
         verticalStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        horizontalStacks.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            verticalStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            verticalStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            verticalStackView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            profileImage.widthAnchor.constraint(equalToConstant: 70),
            profileImage.heightAnchor.constraint(equalTo: profileImage.widthAnchor),
            
            nameLabel.widthAnchor.constraint(equalToConstant: 223),
            loginNameLabel.widthAnchor.constraint(equalToConstant: 89),
            descriptionLabel.widthAnchor.constraint(equalToConstant: 67),
            
            nameLabel.heightAnchor.constraint(equalToConstant: 18),
            loginNameLabel.heightAnchor.constraint(equalToConstant: 18),
            descriptionLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
        
        profileImage.layer.cornerRadius = 35
        nameLabel.layer.cornerRadius = 9
        loginNameLabel.layer.cornerRadius = 9
        descriptionLabel.layer.cornerRadius = 9
        
        profileImage.layer.masksToBounds = true
        nameLabel.layer.masksToBounds = true
        loginNameLabel.layer.masksToBounds = true
        descriptionLabel.layer.masksToBounds = true
    }
    
    func startAnimating() {
        verticalStackView.showAnimatedGradientSkeleton(usingGradient: .init(baseColor: .darkGray))
        
        horizontalStacks.forEach {
            $0.showAnimatedGradientSkeleton(usingGradient: .init(baseColor: .darkGray))
        }
        
        [profileImage, 
         nameLabel,
         loginNameLabel,
         descriptionLabel].forEach {
            $0.showAnimatedGradientSkeleton(usingGradient: .init(baseColor: .darkGray))
        }
    }
    
    private func buildAnimatedViews() -> UIView {
        let view = UIView()
        view.backgroundColor = .ypGray
        view.isSkeletonable = true
        return view
    }
}
