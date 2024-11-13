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
import OktaConcurrency

#if os(Linux)
import FoundationNetworking
#endif

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
    public static var coordinator: any TimeCoordinator {
        get {
            staticLock.withLock {
                _sharedTimeCoordinator
            }
        }
        set {
            staticLock.withLock {
                _sharedTimeCoordinator = newValue
            }
        }
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

fileprivate let staticLock = Lock()
fileprivate nonisolated(unsafe) var _sharedTimeCoordinator: any TimeCoordinator = DefaultTimeCoordinator()

@HasLock
open class DefaultTimeCoordinator: TimeCoordinator, @unchecked Sendable {
    @Synchronized(value: 0.0)
    public var offset: TimeInterval
    
    static func resetToDefault() {
        Date.coordinator = Self()
    }
    
    public required init() {
        self.offset = 0.0
    }
    
    public var now: Date {
        Date(timeIntervalSinceNow: offset)
    }
    
    public func date(from date: Date) -> Date {
        Date(timeInterval: offset, since: date)
    }
}
