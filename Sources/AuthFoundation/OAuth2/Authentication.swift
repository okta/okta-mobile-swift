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
public protocol AuthenticationFlow: AnyObject, UsesDelegateCollection, IDTokenValidatorContext {
    associatedtype Context: AuthenticationContext
    
    /// The object that stores the context and state for the current authentication session.
    var context: Context? { get }

    /// Indicates if this flow is currently authenticating.
    var isAuthenticating: Bool { get }
    
    /// Optional request parameters to be added to requests made from this flow.
    var additionalParameters: [String: APIRequestArgument]? { get }

    /// Resets the authentication session.
    func reset()
    
    /// The collection of delegates this flow notifies for key authentication events.
    var delegateCollection: DelegateCollection<Delegate> { get }
    
    /// Required minimal initializer shared by all authentication flows.
    init(client: OAuth2Client,
         additionalParameters: [String: any APIRequestArgument]?) throws
}

extension AuthenticationFlow {
    @_documentation(visibility: private)
    public var nonce: String? {
        guard let validatorContext = context as? IDTokenValidatorContext
        else {
            return nil
        }

        return validatorContext.nonce
    }

    @_documentation(visibility: private)
    public var maxAge: TimeInterval? {
        guard let validatorContext = context as? IDTokenValidatorContext
        else {
            return nil
        }

        return validatorContext.maxAge
    }
    
    /// Initializer that uses the configuration defined within the application's `Okta.plist` file.
    public init() throws {
        try self.init(try .init())
    }
    
    /// Initializer that uses the configuration defined within the given file URL.
    /// - Parameter fileURL: File URL to a `plist` containing client configuration.
    public init(plist fileURL: URL) throws {
        try self.init(try .init(plist: fileURL))
    }
    
    private init(_ config: OAuth2Client.PropertyListConfiguration) throws {
        try self.init(client: .init(config),
                      additionalParameters: config.additionalParameters)
    }
}

/// Common protocol that all ``AuthenticationFlow`` ``AuthenticationFlow/Context`` type aliases must conform to.
///
/// While instances of a particular ``AuthenticationFlow`` is configured for a particular OAuth2 client, the context supplied to the flow's `start` function represents the specific settings to customize an individual sign-in using that flow.
public protocol AuthenticationContext: ProvidesOAuth2Parameters {
    /// The ACR values, if any, which should be requested by the client.
    var acrValues: [String]? { get }
    
    /// The values from this context that should be persisted into the ``Token/Context-swift.struct`` when the resulting token is created.
    ///
    /// This is used to keep some data critical to the future lifecycle of the token associated with the object in storage, which may not be included in the final token response payload.
    var persistValues: [String: String]? { get }
}

extension AuthenticationContext {
    @_documentation(visibility: internal)
    public var persistValues: [String: String]? {
        if let acrValues = acrValues {
            return ["acr_values": acrValues.joined(separator: " ")]
        }
        
        return nil
    }
}

/// Common ``AuthenticationContext`` implementation for common or generic implementations of ``AuthenticationFlow``.
public struct StandardAuthenticationContext: AuthenticationContext {
    /// The ACR values, if any, which should be requested by the client.
    public var acrValues: [String]?

    /// Custom request parameters to be added to requests made for this particular sign-in attempt.
    public var additionalParameters: [String: any APIRequestArgument]?
    
    /// Designated initializer.
    /// - Parameters:
    ///   - acrValues: Authentication Context Reference values to include with this sign-in.
    ///   - additionalParameters: Custom request parameters to be added to requests made for this sign-in.
    public init(acrValues: [String]? = nil,
                additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        let coalescedAcrValues = (acrValues ?? []) + (additionalParameters?.spaceSeparatedValues(for: "acr_values") ?? [])
        self.acrValues = (acrValues != nil) ? coalescedAcrValues : coalescedAcrValues.nilIfEmpty
        self.additionalParameters = additionalParameters?.omitting("acr_values").nilIfEmpty
    }
    
    @_documentation(visibility: internal)
    public func parameters(for category: OAuth2APIRequestCategory) -> [String: any APIRequestArgument]? {
        var result = additionalParameters ?? [:]
        
        if category == .authorization,
           let acrValues = acrValues
        {
            result["acr_values"] = acrValues.joined(separator: " ")
        }

        return result.nilIfEmpty
    }
}
