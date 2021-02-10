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
