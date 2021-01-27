//
//  IDXButtonTableViewCell.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-13.
//

import UIKit

class IDXButtonTableViewCell: UITableViewCell {
    enum Kind: CaseIterable {
        case restart
        case next
        
        var index: Int {
            switch self {
            case .restart:
                return 0
            case .next:
                return 1
            }
        }
    }
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var continueButton: UIButton!
    var update: ((Any, Kind) -> Void)? = nil
    
    override func prepareForReuse() {
        update = nil
    }

    private func button(for kind: Kind) -> UIButton {
        switch kind {
        case .restart:
            return cancelButton
        case .next:
            return continueButton
        }
    }
    
    private func setButtonVisibility(button kind: Kind, visible: Bool) {
        let buttonView = button(for: kind)
        let isAlreadyVisible = stackView.arrangedSubviews.contains(buttonView)
        if isAlreadyVisible && !visible {
            stackView.removeArrangedSubview(buttonView)
        } else if !isAlreadyVisible && visible {
            stackView.insertArrangedSubview(buttonView,
                                            at: min(kind.index, stackView.arrangedSubviews.count))
        }
    }
    
    var displayKinds: [Kind] = [] {
        didSet {
            Kind.allCases.forEach { kind in
                let visible = displayKinds.contains(kind)
                setButtonVisibility(button: kind, visible: visible)
            }
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if let updateFunc = update {
            updateFunc(sender, .restart)
        }
    }
    
    @IBAction func continueAction(_ sender: Any) {
        if let updateFunc = update {
            updateFunc(sender, .next)
        }
    }
}
