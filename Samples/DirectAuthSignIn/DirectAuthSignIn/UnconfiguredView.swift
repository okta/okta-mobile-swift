//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import SwiftUI

struct UnconfiguredView: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
            Text("""
             The application has not yet been configured. Please open the okta.plist file, and configure it with your organization's connected app settings.
            """)
            .padding(25)
        }
    }
}
