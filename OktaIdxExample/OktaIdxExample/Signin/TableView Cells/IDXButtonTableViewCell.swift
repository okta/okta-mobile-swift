//
//  IDXButtonTableViewCell.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-13.
//

import UIKit
import OktaIdx

class IDXButtonTableViewCell: UITableViewCell {
    enum Style {
        case cancel
        case remediation(type: IDXClient.Remediation.RemediationType)
        
        var backgroundColor: UIColor {
            switch self {
            case .cancel:
                return UIColor.secondarySystemBackground
            case .remediation(type: _):
                return UIColor.link
            }
        }

        var textColor: UIColor {
            switch self {
            case .cancel:
                return UIColor.secondaryLabel
            case .remediation(type: _):
                return UIColor.white
            }
        }
        
        var text: String {
            switch self {
            case .cancel:
                return "Restart"
            case .remediation(type: let type):
                return IDXClient.Remediation.Option.title(for: type)
            }
        }
    }
    
    @IBOutlet var buttonView: UIButton!
    var update: ((Any,Style) -> Void)? = nil
    
    override func prepareForReuse() {
        update = nil
        buttonView.isEnabled = true
    }

    var style: Style = .cancel {
        didSet {
            buttonView.backgroundColor = style.backgroundColor
            buttonView.setTitleColor(style.textColor, for: .normal)
            buttonView.setTitle(style.text, for: .normal)
            buttonView.accessibilityIdentifier = "button.\(style.text)"
        }
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        if let updateFunc = update {
            updateFunc(sender, style)
        }
    }
}
