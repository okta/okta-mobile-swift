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

/// A common delegate protocol that all authentication flows should support.
public protocol AuthenticationDelegate: AnyObject {
    /// Sent when an authentication session starts.
    func authenticationStarted<Flow>(flow: Flow)
    
    /// Sent when an authentication session finishes.
    func authenticationFinished<Flow>(flow: Flow)
    
    /// Sent when an authentication session receives a token.
    func authentication<Flow>(flow: Flow, received token: Token)
    
    /// Sent when an authentication session receives an error.
    func authentication<Flow>(flow: Flow, received error: OAuth2Error)
}

/// A protocol defining a type of authentication flow.
///
/// OAuth2 supports a variety of authentication flows, each with its own capabilities, configuration, and limitations. To normalize these differences, the AuthenticationFlow protocol is used to represent the common capabilities provided by all flows.
public protocol AuthenticationFlow: AnyObject, UsesDelegateCollection {
    /// Indicates if this flow is currently authenticating.
    var isAuthenticating: Bool { get }
    
    /// Resets the authentication session.
    func reset()
}

/// Errors that may be generated during the process of authenticating with a variety of authentication flows.
public enum AuthenticationError: Error {
    case flowNotReady
}
