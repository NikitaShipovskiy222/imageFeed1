
import UIKit

class AlertPresentor: UIViewController {
    
    static let shared = AlertPresentor()
    
    func showNetworkError(with: Error) {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert)
        let action = UIAlertAction(
            title: "ОК",
            style: .default) { _ in
                alert.dismiss(animated: true)
            }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)

    }

}
