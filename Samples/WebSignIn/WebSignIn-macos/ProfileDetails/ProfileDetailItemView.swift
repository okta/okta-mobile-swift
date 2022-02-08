//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import Foundation
import SwiftUI

struct ProfileDetailItemView: View {
    private let leading: String
    private let trailing: String?
    private let placeholder: String
    
    init(leading: String, trailing: String?, placeholder: String = "N/A") {
        self.leading = leading
        self.trailing = trailing
        self.placeholder = placeholder
    }
    
    var body: some View {
        HStack {
            Text(leading).font(.title2).frame(maxWidth: .infinity, alignment: .trailing)
            Text(trailing ?? "N/A").font(.title2).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#if DEBUG
struct ProfileDetailItemView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileDetailItemView(leading: "Username", trailing: "Okta")
    }
}
#endif
