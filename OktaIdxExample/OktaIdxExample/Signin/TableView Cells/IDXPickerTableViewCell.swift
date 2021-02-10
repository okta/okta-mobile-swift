/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import UIKit

class IDXPickerTableViewCell: UITableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var fieldLabel: UILabel!
    var update: ((String) -> Void)? = nil
    var options: [(String,String)] = [] {
        didSet {
            pickerView.reloadAllComponents()
        }
    }
    var selectedValue: String? {
        didSet {
            guard let index = options.firstIndex(where: { $0.0 == selectedValue }) else { return }
            pickerView.selectRow(index, inComponent: 0, animated: false)
        }
    }
    
    override func prepareForReuse() {
        update = nil
        options = []
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        options.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .natural
                
        let margin : CGFloat = 12.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = margin
        paragraphStyle.headIndent = margin
        
        if row == 0 {
            label.font = UIFont.preferredFont(forTextStyle: .caption1)
            label.attributedText = NSAttributedString(string: "Select a value",
                                        attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        } else {
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.attributedText = NSAttributedString(string: options[row - 1].1,
                                        attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])

        }
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        50
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let update = update else { return }
        guard row > 0 else { return }
        update(options[row - 1].0)
    }
}
