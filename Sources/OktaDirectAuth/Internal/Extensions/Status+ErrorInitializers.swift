//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension DirectAuthenticationFlow.Status {
    @usableFromInline
    init?(_ error: any Error) throws {
        switch error {
        case let error as APIClientError:
            try self.init(error)
        case let error as OAuth2Error:
            try self.init(error)
        case let error as OAuth2ServerError:
            try self.init(error)
        case let error as DirectAuthenticationFlowError:
            try self.init(error)
        default:
            return nil
        }
    }

    @usableFromInline
    init?(_ error: OAuth2Error) throws {
        if case let .server(error) = error {
            try self.init(error)
        } else {
            return nil
        }
    }

    @usableFromInline
    init?(_ error: DirectAuthenticationFlowError) throws {
        switch error {
        case .oauth2(let error):
            try self.init(error)
        case .other(let error):
            try self.init(error)
        default:
            return nil
        }
    }

    @usableFromInline
    init?(_ error: APIClientError) throws {
        switch error {
        case .httpError(let error):
            try self.init(error)
        default:
            return nil
        }
    }
    
    @usableFromInline
    init?(_ error: OAuth2ServerError) throws {
        switch error.code {
        case .mfaRequired:
            guard let mfaToken = error.additionalValues["mfaToken"] as? String else {
                throw OAuth2Error.missingOAuth2ResponseKey("mfa_token")
            }

            let supportedTypes = error.additionalValues["supportedChallengeTypes"] as? String
            self = .mfaRequired(.init(supportedChallengeTypes: try .from(string: supportedTypes),
                                      mfaToken: mfaToken))

        default:
            return nil
        }
    }
}
