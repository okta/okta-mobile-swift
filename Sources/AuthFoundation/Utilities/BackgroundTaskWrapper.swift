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

final class BackgroundTask {
    let name: String?

    init(named name: String? = nil) {
        self.name = name
        setup()
    }
    
    deinit {
        finish()
    }

    #if canImport(UIKit) && (os(iOS) || os(tvOS) || targetEnvironment(macCatalyst) || (swift(>=5.10) && os(visionOS)))
    nonisolated(unsafe) private var task: UIBackgroundTaskIdentifier?
    private let lock = Lock()
    #endif
}

// Work around a bug in Swift 5.10 that ignores `nonisolated(unsafe)` on mutable stored properties.
#if swift(<6.0)
extension BackgroundTask: @unchecked Sendable {}
#else
extension BackgroundTask: Sendable {}
#endif

#if canImport(UIKit) && (os(iOS) || os(tvOS) || targetEnvironment(macCatalyst) || (swift(>=5.10) && os(visionOS)))
import UIKit

#if swift(<6.0)
extension UIBackgroundTaskIdentifier: @unchecked Sendable {}
#endif

extension BackgroundTask {
    nonisolated private func setup() {
        Task { @MainActor in
            lock.withLock {
                task = UIApplication.shared.beginBackgroundTask(withName: name)
            }
        }
    }

    nonisolated func finish() {
        guard let task = lock.withLock({ task }) else { return }

        Task { @MainActor in
            UIApplication.shared.endBackgroundTask(task)
        }
    }
}
#else
extension BackgroundTask {
    nonisolated private func setup() {}
    nonisolated func finish() {}
}
#endif
