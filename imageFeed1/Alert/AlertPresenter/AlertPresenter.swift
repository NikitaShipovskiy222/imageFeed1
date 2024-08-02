

import UIKit

// MARK: - Delegate
protocol AlertPresenterDelegate: AnyObject {
    func presentAlert(_ alert: UIAlertController)
}
// MARK: - Object
final class AlertPresenter {
    
    weak var delegate: AlertPresenterDelegate?
    
    static func showAlert(with model: AlertModel, delegate: AlertPresenterDelegate?) {
        let alert = UIAlertController(title: model.title, message: model.message, preferredStyle: .alert)
        
        for button in model.buttons {
            let action = UIAlertAction(title: button.title, style: button.style) { _ in
                button.handler?()
            }
            alert.addAction(action)
        }
        
        switch model.context {
        case .back:
            alert.view.accessibilityIdentifier = "Back"
        case .error:
            alert.view.accessibilityIdentifier = "ErrorAlert"
        case .logout:
            alert.view.accessibilityIdentifier = "Logout"
        }
        
        delegate?.presentAlert(alert)
    }
}
