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

import UIKit
import OktaIdxAuth
import AuthenticationServices

/// This class demonstrates how implementing signin with social auth providers can be implemented.
///
/// The completion handler supplied to the `login` function will be invoked once, either with a fatal error, or with a token.
///
/// Example:
///
/// ```swift
/// let auth = SocialLogin(issuerURL: URL(string: "https://example.okta.com/oauth2/default")!,
///                        clientId: "0oabcde12345",
///                        scope: "openid profile offline_access",
///                        redirectUri: URL(string: "com.example.myapp:/callback")!))
/// let token = try await auth.login(service: .facebook)
/// ```
///
/// If you want to use a custom presentation context, you can optionally supply it to the login method.
public class SocialLogin {
    private let flow: InteractionCodeFlow

    public init(issuerURL: URL,
                clientId: String,
                scope: String,
                redirectUri: URL)
    {
        // Initializes the flow which can be used later in the process.
        flow = InteractionCodeFlow(issuerURL: issuerURL,
                                   clientId: clientId,
                                   scope: scope,
                                   redirectUri: redirectUri)
    }

    /// Public function used to initiate login using a given Social Authentication service.
    ///
    /// Optionally, a presentation context can be supplied when presenting the ASWebAuthenticationSession instance.
    /// - Parameters:
    ///   - service: Social service to authenticate against.
    ///   - presentationContext: Optional presentation context to present login from.
    public func login(service: SocialIDPCapability.Service,
                      from presentationContext: ASWebAuthenticationPresentationContextProviding? = nil) async throws -> Token
    {
        // Begin the authentication flow, returning the list of remediations.
        let response = try await flow.start()
        
        // Find the Social IDP capability within the response that matches our desired service.
        guard let remediation = response.remediations.first(where: { $0.socialIdp?.service == service }),
              let capability = remediation.socialIdp
        else {
            throw LoginError.cannotProceed
        }

        // Present the user with a web sign in form for the social provider,
        // and receive the subsequent redirect URL.
        let callbackUrl = try await socialRedirect(using: capability,
                                                   from: presentationContext)

        // Use the callback URL from ASWebAuthenticationSession
        // to determine if the user is authenticated, or if
        // additional MFA factors need to be verified.
        switch try await flow.resume(with: callbackUrl) {
        case .success(let token):
            // The user is now logged in.
            return token

        case .interactionRequired(let response):
            // The user needs to remediate additional authentication
            // factors. You can use other examples to determine the
            // best way to implement this within your app.
            //
            // For the purposes of this example, we will abort the signin.
            throw LoginError.cannotProceed
        }
    }

    // Present a browser with the social IDP's redirect URL, returning
    // the callback it subsequently redirects to.
    func socialRedirect(using capability: SocialIDPCapability,
                        from presentationContext: ASWebAuthenticationPresentationContextProviding?) async throws -> URL
    {
        // Retrieve the Redirect URL scheme from our configuration, to
        // supply it to the ASWebAuthenticationSession instance.
        guard let scheme = flow.redirectUri.scheme else {
            throw LoginError.cannotProceed
        }

        // Convert the completion block API to Swift Concurrency async/await.
        return try await withCheckedThrowingContinuation { continuation in
            // Create an ASWebAuthenticationSession to trigger the IDP OAuth2 flow.
            let session = ASWebAuthenticationSession(url: capability.redirectUrl,
                                                     callbackURLScheme: scheme)
            { (callbackURL, error) in
                // Ensure no error occurred, and that the callback URL is valid.
                guard error == nil,
                      let callbackURL = callbackURL
                else {
                    continuation.resume(throwing: error ?? LoginError.cannotProceed)
                    return
                }
                
                continuation.resume(returning: callbackURL)
            }
            
            // Start and present the web authentication session.
            session.presentationContextProvider = presentationContext
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }

    public enum LoginError: Error {
        case cannotProceed
    }
}
