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

public final class NotificationRecorder: @unchecked Sendable {
    private(set) public var notifications: [Notification] = []
    public let center: NotificationCenter
    private var observers = [any NSObjectProtocol]()
    
    public init(center: NotificationCenter = .default, observing: [Notification.Name]? = nil) {
        self.center = center
        observing?.forEach {
            observe($0)
        }
    }
    
    deinit {
        observers.forEach { observer in
            center.removeObserver(observer)
        }
    }
    
    public func observe(_ name: Notification.Name, object: AnyObject? = nil) {
        observers.append(center.addObserver(forName: name, object: object, queue: nil, using: { [weak self] notification in
            self?.received(notification)
        }))
    }

    public func notifications(for name: Notification.Name) -> [Notification] {
        notifications.filter { $0.name == name }
    }
    
    public func reset() {
        notifications.removeAll()
    }
    
    private func received(_ notification: Notification) {
        notifications.append(notification)
    }
}
