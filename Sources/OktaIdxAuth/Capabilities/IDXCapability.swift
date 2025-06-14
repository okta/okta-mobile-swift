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
public protocol Capability: Sendable, Equatable, Hashable {
    /// Message sent to capabilities when the response it's contained within will proceed through a remediation.
    /// - Parameter remediation: Remediation being invoked.
    @_documentation(visibility: internal)
    func willProceed(to remediation: Remediation)
}

/// Represents the enumeration type expected within a ``CapabilityCollection``.
///
/// See ``Capability`` for more information.
public protocol IsCapabilityType {
    /// Returns the current capability's underlying value if it matches the given type.
    /// - Parameter type: The capability type requested.
    /// - Returns: The capability's value, or `nil` if it doesn't match the requested type.
    @_documentation(visibility: internal)
    func capability<T: Capability>(of type: T.Type) -> T?
    
    /// Returns this capability as a``Capability`` erased type.
    @_documentation(visibility: internal)
    var capabilityValue: any Capability { get }

    @_documentation(visibility: internal)
    init?(_ capability: any Capability)
}

/// A collection of capabilities that can be associated with some parent object, such as an ``Authenticator`` or ``Remediation``.
///
/// See ``Capability`` for more information.
public protocol CapabilityCollection: AnyObject {
    @_documentation(visibility: internal)
    associatedtype CapabilityType: IsCapabilityType

    /// The collection of all capabilities associated with the parent object.
    var capabilities: [CapabilityType] { get }
    
    /// Returns the capabilities defined by the given type, if available in this collection.
    /// - Parameter type: The type of the capability to return.
    func capabilities<T: Capability>(of type: T.Type) -> [T]
}

extension Authenticator: CapabilityCollection {
    /// Enumeration describing the individual type of capability available within ``Authenticator`` objects, and its associated underlying ``Capability`` instance.
    public enum CapabilityType: IsCapabilityType, Sendable, Equatable, Hashable {
        case sendable(_ capability: SendCapability)
        case resendable(_ capability: ResendCapability)
        case recoverable(_ capability: RecoverCapability)
        case passwordSettings(_ capability: PasswordSettingsCapability)
        case pollable(_ capability: PollCapability)
        case profile(_ capability: ProfileCapability)
        case otp(_ capability: OTPCapability)
        case duo(_ capability: DuoCapability)
        case numberChallenge(_ capability: NumberChallengeCapability)
    }

    /// Exposes the authenticator's capability to send a code.
    ///
    /// If this authenticator is incapable of sending a code, this value will be `nil`.
    ///
    /// See ``Capability`` for more information.
    public var sendable: SendCapability? { capabilities(of: SendCapability.self).first }

    /// Exposes the authenticator's capability to resend a code.
    ///
    /// If this authenticator is incapable of performing this action, this value will be `nil`.
    ///
    /// See ``Capability`` for more information.
    public var resendable: ResendCapability? { capabilities(of: ResendCapability.self).first }

    /// Exposes the authenticator's capability to recover this authenticator.
    ///
    /// If this authenticator is incapable of performing this action, this value will be `nil`.
    public var recoverable: RecoverCapability? { capabilities(of: RecoverCapability.self).first }

    /// Exposes this authenticator's password settings, if available.
    ///
    /// If this authenticator does not have password settings, or those settings are unavailable at this time, this value will be `nil`.
    public var passwordSettings: PasswordSettingsCapability? { capabilities(of: PasswordSettingsCapability.self).first }

    /// Exposes the authenticator's ability to poll for an out-of-band result.
    ///
    /// If this authenticator is incapable of performing this action, this value will be `nil`.
    public var pollable: PollCapability? { capabilities(of: PollCapability.self).first }

    /// Exposes profile information that may be associated with the user account, or this authenticator.
    ///
    /// If no profile information is associated with this authenticator, or is unavailable at this time, the value will be `nil`.
    public var profile: ProfileCapability? { capabilities(of: ProfileCapability.self).first }

    /// Exposes data assocated with one-time-password authenticator enrollment handling.
    public var otp: OTPCapability? { capabilities(of: OTPCapability.self).first }

    /// Exposes data assocated with duo authenticator challenge.
    public var duo: DuoCapability? { capabilities(of: DuoCapability.self).first }

    /// Exposes information related to multiple-choice number challenges.
    public var numberChallenge: NumberChallengeCapability? { capabilities(of: NumberChallengeCapability.self).first }
}

extension Remediation: CapabilityCollection {
    /// Enumeration describing the individual type of capability available within ``Remediation`` objects, and its associated underlying ``Capability`` instance.
    public enum CapabilityType: IsCapabilityType, Sendable, Equatable, Hashable {
        case pollable(_ capability: PollCapability)
        case socialIdp(_ capability: SocialIDPCapability)
    }

    /// Exposes the remediation's ability to poll for an out-of-band result.
    ///
    /// If this remediation is incapable of performing this action, this value will be `nil`.
    public var pollable: PollCapability? { capabilities(of: PollCapability.self).first }

    /// For Social IDP remediation options, this value will describe information related to the social provider, and the resources needed to proceed through this remediation step.
    ///
    /// This value will only be present for social IDP remediation options, and will otherwise be `nil`.
    public var socialIdp: SocialIDPCapability? { allSocialIdps.first }

    /// For Social IDP remediation options, this value will describe information related to the social provider, and the resources needed to proceed through this remediation step.
    ///
    /// This value will only be present for social IDP remediation options, and will otherwise be `nil`.
    public var allSocialIdps: [SocialIDPCapability] { capabilities(of: SocialIDPCapability.self) }
}
