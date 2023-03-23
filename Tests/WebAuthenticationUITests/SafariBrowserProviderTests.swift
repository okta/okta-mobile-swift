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

#if os(iOS)

import XCTest
@testable import AuthFoundation
@testable import TestCommon
@testable import OktaOAuth2
@testable import WebAuthenticationUI

class SafariBrowserProviderTests: ProviderTestBase {
    var provider: SafariBrowserProvider!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        provider = SafariBrowserProvider(loginFlow: loginFlow, logoutFlow: logoutFlow, from: nil, delegate:delegate)
    }
    
    func testControllerCreation() throws {
        provider.start(context: nil, additionalParameters: nil)
        try waitFor(.authenticateUrl)

        // Wait for the controller to dismiss / deallocate
        sleep(1)
        
        XCTAssertNotNil(provider.safariController)
    }
}

#endif
