

import UIKit

struct AlertModel {
    enum Context {
        case back, error, logout
    }
    
    let title: String
    let message: String
    let buttons: [AlertButton]
    let context: Context
}

struct AlertButton {
    let title: String
    let style: UIAlertAction.Style
    let identifier: String?
    let handler: (() -> Void)?
}
