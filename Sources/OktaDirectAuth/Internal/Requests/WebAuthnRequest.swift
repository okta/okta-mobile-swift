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
import AuthFoundation

struct WebAuthnChallengeRequest: AuthenticationFlowRequest {
    typealias Flow = DirectAuthenticationFlow
    
    let url: URL
    let clientConfiguration: OAuth2Client.Configuration
    let context: Flow.Context
    let loginHint: String?
    let mfaToken: String?

    init(openIdConfiguration: OpenIdConfiguration,
         clientConfiguration: OAuth2Client.Configuration,
         context: DirectAuthenticationFlow.Context,
         loginHint: String? = nil,
         mfaToken: String? = nil) throws
    {
        guard let url = openIdConfiguration.primaryAuthenticateEndpoint else {
            throw OAuth2Error.cannotComposeUrl
        }
        
        self.url = url
        self.clientConfiguration = clientConfiguration
        self.context = context
        self.loginHint = loginHint
        self.mfaToken = mfaToken
    }
}

extension WebAuthnChallengeRequest: APIRequest, APIRequestBody {
    typealias ResponseType = WebAuthn.CredentialRequestOptions

    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var category: AuthFoundation.OAuth2APIRequestCategory { .other }
    var bodyParameters: [String: APIRequestArgument]? {
        var result = clientConfiguration.parameters(for: category) ?? [:]
        
        // Only supply context parameters (e.g. intent, max_age, nonce, etc) on the initial request
        if mfaToken == nil {
            result.merge(context.parameters(for: category))
        }
        
        result.merge([
            "challenge_hint": GrantType.webAuthn
        ])
        
        if let loginHint = loginHint {
            result["login_hint"] = loginHint
        }
        
        if let mfaToken = mfaToken {
            result["mfa_token"] = mfaToken
        }
        
        if result["client_id"] == nil {
            result["client_id"] = clientConfiguration.clientId
        }

        return result
    }
}

extension WebAuthn.AuthenticatorAssertionResponse: HasTokenParameters {
    func tokenParameters(currentStatus: DirectAuthenticationFlow.Status?) -> [String: APIRequestArgument] {
        var result = [
            "clientDataJSON": clientDataJSON,
            "authenticatorData": authenticatorData,
            "signature": signature,
        ]
        
        if let userHandle = userHandle {
            result["userHandle"] = userHandle
        }
        
        return result
    }
}
