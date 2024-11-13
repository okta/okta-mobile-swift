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

final class BackgroundTaskOperation: Sendable {
    let description: APITaskDescription?
    private let handler: (any BackgroundTaskHandler)?
    
    @MainActor
    init(_ description: APITaskDescription?) {
        self.description = description
        
        guard let description = description else {
            self.handler = NeverBackgroundTaskHandler()
            return
        }

        #if os(iOS) || os(tvOS) || os(visionOS) || targetEnvironment(macCatalyst)
        self.handler = UIApplicationBackgroundTaskHandler(name: description.name,
                                                          expirationHandler: description.expirationHandler)
        #else
        self.handler = NeverBackgroundTaskHandler()
        #endif
    }
    
    func finish() {
        handler?.finish()
    }
}

protocol BackgroundTaskHandler: Sendable {
    func finish()
}

final class NeverBackgroundTaskHandler: BackgroundTaskHandler {
    func finish() {}
}

#if os(iOS) || os(tvOS) || os(visionOS) || targetEnvironment(macCatalyst)
import UIKit

final class UIApplicationBackgroundTaskHandler: BackgroundTaskHandler {
    private let identifier: UIBackgroundTaskIdentifier
    private let application: UIApplication

    @MainActor
    required init(name: String, expirationHandler handler: (@Sendable () -> Void)?) {
        self.application = UIApplication.shared
        self.identifier = application.beginBackgroundTask(withName: name, expirationHandler: handler)
    }
    
    deinit {
        application.endBackgroundTask(identifier)
    }

    func finish() {
        application.endBackgroundTask(identifier)
    }
}
#endif
