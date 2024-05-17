//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
import UIKit

final class BackgroundTask {
    let task: UIBackgroundTaskIdentifier
    
    init(named name: String? = nil) {
        task = UIApplication.shared.beginBackgroundTask(withName: name)
    }
    
    deinit {
        finish()
    }
    
    func finish() {
        UIApplication.shared.endBackgroundTask(task)
    }
}
#else
final class BackgroundTask {
    init(named name: String? = nil) {}
    
    func finish() {}
}
#endif
