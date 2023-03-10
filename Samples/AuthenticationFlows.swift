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
    let token = try await WebAuthentication.shared?.signIn(from: view.window)
    
    // Save the user's tokens
    try Credential.store(token)
}

func signInWithWebUsingCustomConfiguration() async throws {
    guard let issuerUrl = URL(string: issuer),
          let redirectUrl = URL(string: redirectUri)
    else {
        throw SampleError.invalidUrl
    }
    
    let auth = WebAuthentication(issuer: issuerUrl,
                                 clientId: clientId,
                                 scopes: "openid profile email offline_access device_sso",
                                 redirectUri: redirectUrl)
    
    // Sign in using the above configuration
    let token = try await auth.signIn(from: view.window)
    
    // Save the user's tokens
    let credential = try Credential.store(token)
}

func signInUsingAuthorizationCode() async throws {
    guard let issuerUrl = URL(string: issuer),
          let redirectUrl = URL(string: redirectUri)
    else {
        throw SampleError.invalidUrl
    }
    
    let flow = AuthorizationCodeFlow(issuer: issuerUrl,
                                     clientId: clientId,
                                     scopes: "openid profile email offline_access",
                                     redirectUri: redirectUrl)

    // Initiate the auth flow, and get the URL to present to the user
    let authorizeUrl = try await flow.start()

    // Open that URL in a browser, and wait for the redirect
    let redirectURL: URL // Get the URL from the browser redirect

    // Exchange the redirect URL for a token
    let token = try await flow.resume(with: redirectURL)
    
    // Save the user's tokens
    let credential = try Credential.store(token)
}

func signInUsingResourceOwner(username: String, password: String) async throws {
    guard let issuerUrl = URL(string: issuer) else {
        throw SampleError.invalidUrl
    }
    
    let flow = ResourceOwnerFlow(issuer: issuerUrl,
                                 clientId: clientId,
                                 scopes: "openid profile email offline_access")
    
    // Sign in using a username & password
    let token = try await flow.start(username: username, password: password)
    
    // Save the user's tokens
    let credential = try Credential.store(token)
}

func signInUsingDeviceSSO(deviceToken: String, idToken: String) async throws {
    guard let issuerUrl = URL(string: issuer) else {
        throw SampleError.invalidUrl
    }
    
    // Create the flow
    let flow = TokenExchangeFlow(issuer: issuerUrl,
                                 clientId: clientId,
                                 scopes: "openid profile offline_access",
                                 audience: .default)
    
    // Exchange the ID and Device tokens for access tokens.
    let token = try await flow.start(with: [
        .actor(type: .deviceSecret, value: deviceToken),
        .subject(type: .idToken, value: idToken)
    ])

    // Save the user's token
    let credential = try Credential.store(token)
}

func signInUsingDeviceAuthorizationCode() async throws {
    guard let issuerUrl = URL(string: issuer) else {
        throw SampleError.invalidUrl
    }
    
    let flow = DeviceAuthorizationFlow(issuer: issuerUrl,
                                       clientId: clientId,
                                       scopes: "openid profile email offline_access")

    // Initiate the auth flow, and get the user code to display to the user
    let context = try await flow.start()

    print("Go to \(context.verificationUri.absoluteString) and enter \(context.userCode)")
    
    // Poll the server, waiting for a successful login
    let token = try await flow.resume(with: context)
    
    // Save the user's tokens
    let credential = try Credential.store(token)
}

enum SampleError: Error {
    case invalidUrl
}
