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
import AuthFoundation

#if !COCOAPODS
import CommonSupport
#endif

#if !COCOAPODS
import CommonSupport
#endif

/// Capability to access data related to Duo
public final class DuoCapability: Capability, Sendable, Equatable, Hashable {
    public let host: String
    public let signedToken: String
    public let script: String
    public var signatureData: String? {
        get { _signatureData.wrappedValue }
        set { _signatureData.wrappedValue = newValue }
    }

    @_documentation(visibility: internal)
    public func willProceed(to remediation: Remediation) {
        guard remediation.authenticators.contains(where: {
            $0.type == .app && $0.methods?.contains(.duo) ?? false
        }),
              let signatureField = remediation.form[allFields: "credentials.signatureData"]
        else {
            return
        }

        signatureField.value = signatureData
    }

    @_documentation(visibility: internal)
    public static func == (lhs: DuoCapability, rhs: DuoCapability) -> Bool {
        lhs.host == rhs.host &&
        lhs.signedToken == rhs.signedToken &&
        lhs.script == rhs.script &&
        lhs._signatureData.wrappedValue == rhs._signatureData.wrappedValue
    }

    @_documentation(visibility: internal)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(host)
        hasher.combine(signedToken)
        hasher.combine(script)
        hasher.combine(_signatureData.wrappedValue)
    }

    private let _signatureData = LockedValue<String?>(nil)
    init(host: String, signedToken: String, script: String, signatureData: String? = nil) {
        self.host = host
        self.signedToken = signedToken
        self.script = script
        if let signatureData {
            self._signatureData.wrappedValue = signatureData
        }
    }
}
