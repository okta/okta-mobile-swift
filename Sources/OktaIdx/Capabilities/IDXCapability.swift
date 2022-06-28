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

/// A generic protocol used to identify objects that describe a capability.
public protocol IDXCapability {}

/// Defines type conformance for capabilities that can be used with Authenticators.
public protocol AuthenticatorCapability: IDXCapability {}

/// Defines type conformance for capabilities that can be used with Remediations.
public protocol RemediationCapability: IDXCapability {}

public struct Capability {}

/// A collection of capabilities that can be associated with some parent object, such as an ``Authenticator`` or ``Remediation``.
public protocol CapabilityCollection: AnyObject {
    associatedtype CapabilityType

    /// The collection of capabilities associated with the parent object.
    var capabilities: [CapabilityType] { get }
    
    /// Returns the capability defined by the given type, if available in this collection.
    /// - Parameter type: The type of the capability to return.
    func capability<T: IDXCapability>(_ type: T.Type) -> T?
}

public extension CapabilityCollection {
    func capability<T: IDXCapability>(_ type: T.Type) -> T? {
        capabilities.first { $0 is T } as? T
    }
}

extension Authenticator: CapabilityCollection {
    public typealias CapabilityType = AuthenticatorCapability
    
    /// Exposes the authenticator's capability to send a code.
    ///
    /// If this authenticator is incapable of sending a code, this value will be `nil`.
    public var sendable: Capability.Sendable? { capability(Capability.Sendable.self) }
    
    /// Exposes the authenticator's capability to resend a code.
    ///
    /// If this authenticator is incapable of performing this action, this value will be `nil`.
    public var resendable: Capability.Resendable? { capability(Capability.Resendable.self) }
    
    /// Exposes the authenticator's capability to recover this authenticator.
    ///
    /// If this authenticator is incapable of performing this action, this value will be `nil`.
    public var recoverable: Capability.Recoverable? { capability(Capability.Recoverable.self) }
    
    /// Exposes this authenticator's password settings, if available.
    ///
    /// If this authenticator does not have password settings, or those settings are unavailable at this time, this value will be `nil`.
    public var passwordSettings: Capability.PasswordSettings? { capability(Capability.PasswordSettings.self) }
    
    /// Exposes the authenticator's ability to poll for an out-of-band result.
    ///
    /// If this authenticator is incapable of performing this action, this value will be `nil`.
    public var pollable: Capability.Pollable? { capability(Capability.Pollable.self) }
    
    /// Exposes profile information that may be associated with the user account, or this authenticator.
    ///
    /// If no profile information is associated with this authenticator, or is unavailable at this time, the value will be `nil`.
    public var profile: Capability.Profile? { capability(Capability.Profile.self) }
    
    /// Exposes data assocated with one-time-password authenticator enrollment handling.
    public var otp: Capability.OTP? { capability(Capability.OTP.self) }

    /// Exposes information related to multiple-choice number challenges.
    public var numberChallenge: Capability.NumberChallenge? { capability(Capability.NumberChallenge.self) }
}

extension Remediation: CapabilityCollection {
    public typealias CapabilityType = RemediationCapability
    
    /// Exposes the remediation's ability to poll for an out-of-band result.
    ///
    /// If this remediation is incapable of performing this action, this value will be `nil`.
    public var pollable: Capability.Pollable? { capability(Capability.Pollable.self) }

    /// For Social IDP remediation options, this value will describe information related to the social provider, and the resources needed to proceed through this remediation step.
    ///
    /// This value will only be present for social IDP remediation options, and will otherwise be `nil`.
    public var socialIdp: Capability.SocialIDP? { capability(Capability.SocialIDP.self) }
}
