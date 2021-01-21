//
//  IDXSwitchTableViewCell.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-13.
//

import UIKit

class IDXToggleTableViewCell: UITableViewCell {
    @IBOutlet weak var fieldLabel: UILabel!
    @IBOutlet weak var switchView: UISwitch!
    var update: ((Bool) -> Void)? = nil
    
    override func prepareForReuse() {
        update = nil
        switchView.isOn = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        switchView.setOn(!switchView.isOn, animated: true)
        if let updateFunc = update {
            updateFunc(switchView.isOn)
        }
    }
    
    @IBAction func valueChanged(_ sender: Any) {
        if let updateFunc = update {
            updateFunc(switchView.isOn)
        }
    }
}
