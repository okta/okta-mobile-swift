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
    @IBOutlet weak var detailLabel: UILabel!
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
