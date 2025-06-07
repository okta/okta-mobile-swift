/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import OktaIdxAuth

class IDXButtonTableViewCell: UITableViewCell {
    enum Style {
        case cancel
        case remediation(type: Remediation.RemediationType)
        
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
                return Remediation.title(for: type)
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
