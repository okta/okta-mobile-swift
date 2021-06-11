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

@IBDesignable
class FooterView: UIView {
    @IBInspectable
    var curveOffset: CGFloat = 24 {
        didSet {
            maskLayer.path = path()
        }
    }
    
    var maskLayer = CAShapeLayer()
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        if layer.mask == nil {
            layer.mask = maskLayer
        }
        
        maskLayer.path = path()
    }

    func path() -> CGPath {
        let path = UIBezierPath()
        
        path.move(to: bounds.topLeft)
        path.addQuadCurve(to: bounds.topRight,
                          controlPoint: bounds.topMiddle.offsetBy(dy: curveOffset * 2))
        path.addLine(to: bounds.bottomRight)
        path.addLine(to: bounds.bottomLeft)
        path.addLine(to: bounds.topLeft)
        path.close()
        return path.cgPath
    }
}
