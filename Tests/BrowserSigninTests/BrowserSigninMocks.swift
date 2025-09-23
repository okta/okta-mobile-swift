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

import XCTest
@testable import AuthFoundation
@testable import OAuth2Auth
@testable import BrowserSignin

struct BrowserSigninProviderFactoryMock: BrowserSignin.ProviderFactory {
    nonisolated(unsafe) private static var results: [String: Result<URL, any Error>?] = [:]
    nonisolated(unsafe) private static var providers: [String: BrowserSigninProviderMock] = [:]
    
    enum TestError: Error {
        case invalidTestName
    }
    
    static func register(result: Result<URL, any Error>?, for webAuth: BrowserSignin) async throws {
        guard let testName = webAuth.signInFlow.additionalParameters?["testName"] as? String
        else {
            throw TestError.invalidTestName
        }
        
        results[testName] = result
    }
    
    static func provider(for webAuth: BrowserSignin) async -> BrowserSigninProviderMock? {
        guard let testName = webAuth.signInFlow.additionalParameters?["testName"] as? String
        else {
            return nil
        }
        
        return providers[testName]
    }
    
    static func createWebAuthenticationProvider(for browserSignin: BrowserSignin,
                                                from window: BrowserSignin.WindowAnchor?,
                                                options: BrowserSignin.Option) async throws -> (any BrowserSignin.Provider)?
    {
        let testName = browserSignin.signInFlow.additionalParameters?["testName"] as? String

        var result: Result<URL, any Error>?
        if let testName,
           let testResult = results[testName]
        {
            result = testResult
        }

        let provider = BrowserSigninProviderMock(from: window,
                                                 usesEphemeralSession: options.contains(.ephemeralSession),
                                                 result: result)
        if let testName {
            providers[testName] = provider
        }
        
        return provider
    }
}

class BrowserSigninProviderMock: @unchecked Sendable, BrowserSignin.Provider {
    let anchor: BrowserSignin.WindowAnchor?
    let usesEphemeralSession: Bool
    
    enum State {
        case initialized
        case opened(authorizeUrl: URL, redirectUri: URL)
        case cancelled
    }
    
    var state: State = .initialized
    let result: Result<URL, any Error>?
    
    init(from anchor: BrowserSignin.WindowAnchor?, usesEphemeralSession: Bool, result: Result<URL, any Error>? = nil) {
        self.anchor = anchor
        self.usesEphemeralSession = usesEphemeralSession
        self.result = result
    }
    
    func open(authorizeUrl: URL, redirectUri: URL) async throws -> URL {
        state = .opened(authorizeUrl: authorizeUrl, redirectUri: redirectUri)
        
        switch result {
        case .success(let url):
            return url
        case .failure(let error):
            let error = BrowserSigninError(error)
            if error == .userCancelledLogin() {
                state = .cancelled
            }
            throw error
        case nil:
            throw BrowserSigninError.noAuthenticatorProviderResonse
        }
    }
    
    func cancel() {
        state = .cancelled
    }
}
