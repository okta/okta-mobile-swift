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
public protocol TimeCoordinator {
    var now: Date { get }
    func date(from date: Date) -> Date
}

extension Date {
    /// Returns times calculated or adjusted against a trusted clock.
    public static var coordinator: TimeCoordinator {
        get { SharedTimeCoordinator }
        set { SharedTimeCoordinator = newValue }
    }
    
    public static var nowCoordinated: Date {
        coordinator.now
    }
    
    public var coordinated: Date {
        Date.coordinator.date(from: self)
    }
}

fileprivate var SharedTimeCoordinator: TimeCoordinator = DefaultTimeCoordinator()
struct DefaultTimeCoordinator: TimeCoordinator {
    var now: Date {
        if #available(iOS 15, tvOS 15, *) {
            return .now
        } else {
            return Date()
        }
    }
    
    func date(from date: Date) -> Date {
        date
    }
}
