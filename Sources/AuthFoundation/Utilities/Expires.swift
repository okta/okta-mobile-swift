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

/// Protocol that indicates an object is capable of expiring.
///
/// This protocol contains convenience properties that enables a developer to identify whether or not the object in question has expired, how long it will be until it expires, and whether or not the object is valid.
public protocol Expires {
    /// Time interval from the issue date when the object will expire.
    var expiresIn: TimeInterval { get }
    
    /// The calculated date at which this object will expire.
    var expiresAt: Date? { get }
    
    /// The date this object was issued, from which the expiration time will be calculated.
    var issuedAt: Date? { get }
    
    /// Indicates if this object has expired.
    var isExpired: Bool { get }
    
    /// Indicates if this object is valid.
    var isValid: Bool { get }
}

extension Expires {
    public var expiresAt: Date? {
        issuedAt?.addingTimeInterval(expiresIn)
    }

    public var isExpired: Bool {
        guard let expiresAt = expiresAt else {
            return false
        }

        return Date.nowCoordinated > expiresAt
    }
    
    public var isValid: Bool { !isExpired }
}
