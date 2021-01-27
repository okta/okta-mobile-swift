//
//  IDXMessageTableViewCell.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-14.
//

import UIKit
import OktaIdx
extension IDXClient.Message.MessageClass {
    var image: UIImage? {
        switch self {
        case .error:
            return UIImage(systemName: "exclamationmark.triangle")
        case .info:
            return UIImage(systemName: "info.circle")
        default:
            return nil
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .error:
            return UIColor.systemRed
        case .info: fallthrough
        default:
            return UIColor.darkText
        }
    }
}

class IDXMessageTableViewCell: UITableViewCell {
    @IBOutlet weak var messageTypeImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    var update: (() -> Void)? = nil
    
    enum Style {
        case message(message: IDXClient.Message)
        case enrollment(action: Signin.EnrollmentAction)
        
        var image: UIImage? {
            switch self {
            case .message(message: let message):
                return message.type.image
            case .enrollment(action: let action):
                switch action {
                case .send: fallthrough
                case .resend:
                    return UIImage(systemName: "phone.arrow.right")
                case .recover:
                    return UIImage(systemName: "lock.rotation")
                }
            }
        }

        var textColor: UIColor? {
            switch self {
            case .message(message: let message):
                return message.type.textColor
            case .enrollment(action: _):
                return UIColor.darkText
            }
        }
        
        var accessibilityIdentifier: String? {
            switch self {
            case .message(message: let message):
                return message.localizationKey
            case .enrollment(action: let action):
                switch action {
                case .send:
                    return "send"
                case .resend:
                    return "resend"
                case .recover:
                    return "recover"
                }
            }
        }

        var text: String? {
            switch self {
            case .message(message: let message):
                return message.message
            case .enrollment(action: let action):
                switch action {
                case .send:
                    return "Send"
                case .resend:
                    return "Send again"
                case .recover:
                    return "Recover your account"
                }
            }
        }
    }
    
    override func prepareForReuse() {
        update = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizer)))
    }
    
    var type: Style? = nil {
        didSet {
            messageTypeImageView.image = type?.image
            messageLabel.accessibilityIdentifier = type?.accessibilityIdentifier
            messageLabel.textColor = type?.textColor
            messageLabel.text = type?.text
        }
    }
    
    @objc func tapGestureRecognizer() {
        if let updateFunc = update {
            updateFunc()
        }
    }
}
