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

/// Describes the password complexity settings.
public struct PasswordSettingsCapability: Capability, Sendable, Hashable, Equatable {
    /// The number of days before a password will expire.
    public let daysToExpiry: Int

    /// The minimum password length.
    public let minLength: Int

    /// The minimum number of lower-case characters.
    public let minLowerCase: Int

    /// The minimum  number of upper-case characters.
    public let minUpperCase: Int

    /// The minimum number of numeric characters.
    public let minNumber: Int

    /// The minimum number of symbols (e.g. non-alpha-numeric characters).
    public let minSymbol: Int

    /// The maximum number of repeated characters.
    public let maxConsecutiveRepeatingCharacters: Int

    /// Indicates the user's username cannot be used in the password.
    public let excludeUsername: Bool

    /// Indicates the user's attributes that cannot be used within the password.
    public let excludeAttributes: [String]

    init(daysToExpiry: Int,
         minLength: Int,
         minLowerCase: Int,
         minUpperCase: Int,
         minNumber: Int,
         minSymbol: Int,
         maxConsecutiveRepeatingCharacters: Int,
         excludeUsername: Bool,
         excludeAttributes: [String])
    {
        self.daysToExpiry = daysToExpiry
        self.minLength = minLength
        self.minLowerCase = minLowerCase
        self.minUpperCase = minUpperCase
        self.minNumber = minNumber
        self.minSymbol = minSymbol
        self.maxConsecutiveRepeatingCharacters = maxConsecutiveRepeatingCharacters
        self.excludeUsername = excludeUsername
        self.excludeAttributes = excludeAttributes
    }
}

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension PasswordSettingsCapability {
    /// A UITextInputPasswordRules object representing the password complexity rules.
    @MainActor public var passwordRules: UITextInputPasswordRules {
        var rules: [String] = []

        if minLength > 0 {
            rules.append("required: minlength: \(minLength)")
        }
        if minLowerCase > 0 {
            rules.append("required: lower: \(minLowerCase)")
        }
        if minUpperCase > 0 {
            rules.append("required: upper: \(minUpperCase)")
        }
        if minNumber > 0 {
            rules.append("required: digit: \(minNumber)")
        }
        if minSymbol > 0 {
            rules.append("required: symbol: \(minSymbol)")
        }
        if maxConsecutiveRepeatingCharacters > 0 {
            rules.append("required: max-consecutive: \(maxConsecutiveRepeatingCharacters)")
        }

        let rulesString = rules.joined(separator: ";\n")
        return UITextInputPasswordRules(descriptor: rulesString)
    }
}
#endif
