//
//  IDXOptionTableViewCell.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-13.
//

import UIKit

class IDXOptionTableViewCell: UITableViewCell {
    enum State {
        case checked
        case unchecked
        
        var image: UIImage? {
            switch self {
            case .checked:
                return UIImage(systemName: "smallcircle.fill.circle")
            case .unchecked:
                return UIImage(systemName: "circle")
            }
        }

        static prefix func ! (state: State) -> State {
            switch state {
            case .checked:
                return .unchecked
            case .unchecked:
                return .checked
            }
        }
    }
    
    @IBOutlet weak var fieldLabel: UILabel!
    @IBOutlet weak var checkmarkView: UIImageView!
    var update: (() -> Void)? = nil
    
    override func prepareForReuse() {
        update = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizer)))
    }
    
    var state: State = .unchecked {
        didSet {
            checkmarkView.image = state.image
        }
    }
        
    @objc func tapGestureRecognizer() {
        state = !state
        if let updateFunc = update {
            updateFunc()
        }
    }
}
