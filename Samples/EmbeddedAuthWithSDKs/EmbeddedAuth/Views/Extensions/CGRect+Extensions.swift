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

extension CGRect {
    var topLeft: CGPoint {
        CGPoint(x: minX, y: minY)
    }
    
    var topMiddle: CGPoint {
        CGPoint(x: midX, y: minY)
    }

    var topRight: CGPoint {
        CGPoint(x: maxX, y: minY)
    }
    
    var bottomLeft: CGPoint {
        CGPoint(x: minX, y: maxY)
    }

    var bottomRight: CGPoint {
        CGPoint(x: maxX, y: maxY)
    }
}

extension CGPoint {
    func offsetBy(dx: CGFloat = 0, dy: CGFloat = 0) -> CGPoint {
        CGPoint(x: x + dx, y: y + dy)
    }
}
