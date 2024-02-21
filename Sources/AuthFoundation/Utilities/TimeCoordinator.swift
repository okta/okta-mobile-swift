//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Protocol used to return dates and times coordinated against trusted sources.
///
/// This can be used to customize the behavior of how dates and times are calculated, when used on devices that may have skewed or incorrect clocks.
///
/// To use a custom ``TimeCoordinator``, you construct an instance of your class conforming to this protocol, and assign it to the `Date.coordinator` property.
public protocol TimeCoordinator {
    /// Return the current coordinated date.
    var now: Date { get }
    
    /// Returns a coordinated version of the given date.
    /// - Returns: Date instance, adjusted to the appropriate time offset.
    func date(from date: Date) -> Date
}

extension Date {
    /// Allows a custom ``TimeCoordinator`` to be used to adjust dates and times for devices with incorrect times.
    public static var coordinator: TimeCoordinator {
        get { SharedTimeCoordinator }
        set { SharedTimeCoordinator = newValue }
    }
    
    /// Returns the current coordinated date, adjusting the system clock to correct for clock skew.
    public static var nowCoordinated: Date {
        coordinator.now
    }
    
    /// Returns the coordinated version of this date, adjusting the system clock to correct for clock skew.
    public var coordinated: Date {
        Date.coordinator.date(from: self)
    }
}

// swiftlint:disable identifier_name
private var SharedTimeCoordinator: TimeCoordinator = DefaultTimeCoordinator()
// swiftlint:enable identifier_name

class DefaultTimeCoordinator: TimeCoordinator, OAuth2ClientDelegate {
    static func resetToDefault() {
        Date.coordinator = DefaultTimeCoordinator()
    }
    
    private let lock = UnfairLock()
    private var _offset: TimeInterval
    private(set) var offset: TimeInterval {
        get { lock.withLock { _offset } }
        set { lock.withLock { _offset = newValue } }
    }
    
    private var observer: NSObjectProtocol?

    init() {
        self._offset = 0
        self.observer = NotificationCenter.default.addObserver(forName: .oauth2ClientCreated,
                                                               object: nil,
                                                               queue: nil,
                                                               using: { [weak self] notification in
            guard let self = self,
                  let client = notification.object as? OAuth2Client
            else {
                return
            }
            
            client.add(delegate: self)
        })
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    var now: Date {
        Date(timeIntervalSinceNow: offset)
    }
    
    func date(from date: Date) -> Date {
        Date(timeInterval: offset, since: date)
    }
    
    func api(client: APIClient, didSend request: URLRequest, received response: HTTPURLResponse) {
        guard request.cachePolicy == .reloadIgnoringLocalAndRemoteCacheData,
              let dateString = response.allHeaderFields["Date"] as? String,
              let date = httpDateFormatter.date(from: dateString)
        else {
            return
        }
        
        offset = date.timeIntervalSinceNow
    }
}
