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

import UIKit
import WebAuthenticationUI

let issuer = "https://<#domain#>"
let clientId = "<#clientId#>"
let redirectUri = "<#redirectUri#>"

func signInWithWeb() async throws {
    // Sign in using the default configuration
    let token = try await WebAuthentication.signIn(from: view.window)
    
    // Save the user's tokens
    Credential.default = Credential(token: token)
}

func signInWithWebUsingCustomConfiguration() async throws {
    let auth = WebAuthentication(issuer: URL(string: issuer)!,
                                 clientId: clientId,
                                 scopes: "openid profile email offline_access device_sso",
                                 redirectUri: URL(string: redirectUri)!)
    
    // Sign in using the above configuration
    let token = try await auth.start(from: view.window)
    
    // Save the user's tokens
    Credential.default = Credential(token: token)
}

func signInUsingResourceOwner(username: String, password: String) async throws {
    let flow = ResourceOwnerFlow(issuer: URL(string: issuer)!,
                                 clientId: clientId,
                                 scopes: "openid profile email offline_access")
    
    // Sign in using a username & password
    let token = try await flow.resume(username: username, password: password)
    
    // Save the user's tokens
    Credential.default = Credential(token: token)
}

func signInUsingDeviceSSO(deviceToken: String, idToken: String) async throws {
    // Create the flow
    let flow = TokenExchangeFlow(issuer: URL(string: issuer)!,
                                 clientId: clientId,
                                 scopes: "openid profile offline_access",
                                 audience: .default)
    
    // Exchange the ID and Device tokens for access tokens.
    let token = try await flow.resume(with: [
        .actor(type: .deviceSecret, value: deviceToken),
        .subject(type: .idToken, value: idToken)
    ])

    // Save the user's token
    Credential.default = Credential(token: token)
}

func signInUsingDeviceAuthorizationCode() async throws {
    let flow = DeviceAuthorizationFlow(issuer: URL(string: issuer)!,
                                       clientId: clientId,
                                       scopes: "openid profile email offline_access")

    // Initiate the auth flow, and get the user code to display to the user
    let context = try await flow.resume()

    print("Go to \(context.verificationUri.absoluteString) and enter \(context.userCode)")
    
    // Poll the server, waiting for a successful login
    let token = try await flow.resume(with: context)
    
    // Save the user's tokens
    Credential.default = Credential(token: token)
}

