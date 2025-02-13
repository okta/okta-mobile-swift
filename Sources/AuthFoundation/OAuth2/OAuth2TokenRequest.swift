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

/// Protocol that represents a type of ``APIRequest`` that can be used to exchange a token.
///
/// Many different OAuth2 authentication flows can issue tokens, but the types of arguments and their particular workflow can differ. This protocol abstracts the necessary interface for requests that are capable of returning tokens, while allowing the specific arguments and validation steps to be implemented for each unique type of flow.
public protocol OAuth2TokenRequest: APIParsingContext, OAuth2APIRequest, APIRequestBody where ResponseType == Token {
    /// The configuration for the OAuth2 client this token is being requested from.
    var clientConfiguration: OAuth2Client.Configuration { get }
    
    /// The originating request context to use when validating the ID token.
    var tokenValidatorContext: any IDTokenValidatorContext { get }
}

extension OAuth2TokenRequest {
    public var url: URL { openIdConfiguration.tokenEndpoint }
    public var httpMethod: APIRequestMethod { .post }
    public var contentType: APIContentType? { .formEncoded }
    public var acceptsType: APIContentType? { .json }
}
