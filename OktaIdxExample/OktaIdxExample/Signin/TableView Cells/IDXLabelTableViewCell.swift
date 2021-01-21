//
//  IDXLabelTableViewCell.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-14.
//

import UIKit

class IDXLabelTableViewCell: UITableViewCell {
    @IBOutlet weak var fieldLabel: UILabel!

    override func prepareForReuse() {
        fieldLabel.text = nil
    }
}
