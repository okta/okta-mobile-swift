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

extension Capability {
    public func willProceed(to remediation: Remediation) {}
}

extension CapabilityCollection {
    public func capabilities<T: Capability>(of type: T.Type) -> [T] {
        capabilities.compactMap { $0.capability(of: type) }
    }
}

extension IsCapabilityType {
    func willProceed(to remediation: Remediation) {
        capabilityValue.willProceed(to: remediation)
    }

    public func capability<T: Capability>(of type: T.Type) -> T? {
        capabilityValue as? T
    }
}

extension Authenticator.CapabilityType {
    public init?(_ capability: any Capability) {
        if let capability = capability as? SendCapability {
            self = .sendable(capability)
        } else if let capability = capability as? ResendCapability {
            self = .resendable(capability)
        } else if let capability = capability as? RecoverCapability {
            self = .recoverable(capability)
        } else if let capability = capability as? PasswordSettingsCapability {
            self = .passwordSettings(capability)
        } else if let capability = capability as? PollCapability {
            self = .pollable(capability)
        } else if let capability = capability as? ProfileCapability {
            self = .profile(capability)
        } else if let capability = capability as? OTPCapability {
            self = .otp(capability)
        } else if let capability = capability as? DuoCapability {
            self = .duo(capability)
        } else if let capability = capability as? NumberChallengeCapability {
            self = .numberChallenge(capability)
        } else {
            return nil
        }
    }

    public var capabilityValue: any Capability {
        switch self {
        case .sendable(let capability):
            return capability
        case .resendable(let capability):
            return capability
        case .recoverable(let capability):
            return capability
        case .passwordSettings(let capability):
            return capability
        case .pollable(let capability):
            return capability
        case .profile(let capability):
            return capability
        case .otp(let capability):
            return capability
        case .duo(let capability):
            return capability
        case .numberChallenge(let capability):
            return capability
        }
    }
}

extension Remediation.CapabilityType {
    public init?(_ capability: any Capability) {
        if let capability = capability as? PollCapability {
            self = .pollable(capability)
        } else if let capability = capability as? SocialIDPCapability {
            self = .socialIdp(capability)
        } else {
            return nil
        }
    }

    public var capabilityValue: any Capability {
        switch self {
        case .pollable(let capability):
            return capability
        case .socialIdp(let capability):
            return capability
        }
    }
}
