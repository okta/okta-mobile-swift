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
    
    var type: IDXClient.Message.MessageClass? = nil {
        didSet {
            messageTypeImageView.image = type?.image
            messageLabel.textColor = type?.textColor ?? UIColor.lightText
        }
    }
}
