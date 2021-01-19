//
//  IDXMessageTableViewCell.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-14.
//

import UIKit

class IDXMessageTableViewCell: UITableViewCell {
    enum MessageType: String {
        case error = "ERROR"
        
        var image: UIImage? {
            switch self {
            case .error:
                return UIImage(systemName: "exclamationmark.bubble")
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .error:
                return UIColor.systemRed
            }
        }
    }
    

    @IBOutlet weak var messageTypeImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var type: MessageType? = nil {
        didSet {
            messageTypeImageView.image = type?.image
            messageLabel.textColor = type?.textColor ?? UIColor.lightText
        }
    }
}
