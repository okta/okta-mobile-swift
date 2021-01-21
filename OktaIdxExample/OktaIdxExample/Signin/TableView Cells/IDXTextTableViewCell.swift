//
//  IDXTextFormValueTableViewCell.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-13.
//

import UIKit

class IDXTextTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var fieldLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    var update: ((String) -> Void)? = nil
    
    override func prepareForReuse() {
        update = nil
        textField.text = nil
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        textField.becomeFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text,
           let textRange = Range(range, in: text) {
           let updatedText = text.replacingCharacters(in: textRange,
                                                       with: string)
            if let updateFunc = update {
                updateFunc(updatedText)
            }
        }
        return true
    }
}
