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

#if canImport(AuthenticationServices)

import XCTest
@testable import AuthFoundation
@testable import TestCommon
@testable import OktaOAuth2
@testable import WebAuthenticationUI
import AuthenticationServices

@available(iOS 12.0, *)
class AuthenticationServicesProviderTests: ProviderTestBase {
    var provider: AuthenticationServicesProvider!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        provider = AuthenticationServicesProvider(flow: flow, from: nil, delegate: delegate)
    }
    
    func testSuccessfulAuthentication() {
        provider.start(context: .init(state: "state"))
        waitFor(.authenticateUrl)
        
        XCTAssertNotNil(provider.authenticationSession)
     
        let redirectUrl = URL(string: "com.example:/callback?code=abc123&state=state")
        provider.process(url: redirectUrl, error: nil)
        waitFor(.token)
        
        XCTAssertNotNil(delegate.token)
        XCTAssertNil(delegate.error)
    }

    func testErrorResponse() {
        provider.start(context: .init(state: "state"))
        waitFor(.authenticateUrl)

        XCTAssertNotNil(provider.authenticationSession)
     
        let redirectUrl = URL(string: "com.example:/callback?state=state&error=errorname&error_description=This+Thing+Failed")
        provider.process(url: redirectUrl, error: nil)
        XCTAssertNil(delegate.token)
        XCTAssertNotNil(delegate.error)
    }

    func testUserCancelled() {
        provider.start(context: .init(state: "state"))
        waitFor(.authenticateUrl)

        XCTAssertNotNil(provider.authenticationSession)
     
        let error = NSError(domain: ASWebAuthenticationSessionErrorDomain,
                            code: ASWebAuthenticationSessionError.canceledLogin.rawValue,
                            userInfo: nil)
        provider.process(url: nil, error: error)
        XCTAssertNil(delegate.token)
        XCTAssertNotNil(delegate.error)
    }

    func testNoResponse() {
        provider.start(context: .init(state: "state"))
        waitFor(.authenticateUrl)

        XCTAssertNotNil(provider.authenticationSession)
     
        provider.process(url: nil, error: nil)
        XCTAssertNil(delegate.token)
        XCTAssertNotNil(delegate.error)
    }
}

#endif
