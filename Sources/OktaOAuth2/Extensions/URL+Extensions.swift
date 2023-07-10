//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension URL {
    typealias RedirectError = AuthorizationCodeFlow.RedirectError
    
    func oauth2QueryComponents(redirectUri: URL?) throws -> [String: String] {
        guard let components = URLComponents(url: self,
                                             resolvingAgainstBaseURL: false)
        else {
            throw RedirectError.invalidRedirectUrl
        }
        
        guard components.scheme?.lowercased() == redirectUri?.scheme?.lowercased()
        else {
            throw RedirectError.unexpectedScheme(components.scheme)
        }
        
        guard var query = components.queryItems?.reduce(into: [String: String](), { partialResult, queryItem in
            if let value = queryItem.value {
                partialResult[queryItem.name] = value
            }
        }) else {
            throw RedirectError.missingQueryArguments
        }
        
        if let description = query["error_description"]?
            .removingPercentEncoding?
            .replacingOccurrences(of: "+", with: " ")
        {
            query["error_description"] = description
        }
        
        return query
    }
    
    func errorFrom(query: [String: String]) -> OAuth2ServerError? {
        guard let errorCode = query["error"] else {
            return nil
        }

        let additionalKeys = query.filter { element in
            element.key != "error" && element.key != "error_description"
        }
        
        return OAuth2ServerError(code: errorCode,
                                 description: query["error_description"],
                                 additionalValues: additionalKeys)

    }
    
    /// Convenience function to return an authorization code from the given URL.
    /// - Parameters:
    ///   - redirectUri: Redirect URI to match against.
    ///   - state: State token to match against.
    /// - Returns: The authorization code for the given URI.
    public func authorizationCode(redirectUri: URL, state: String) throws -> String {
        let query = try oauth2QueryComponents(redirectUri: redirectUri)
        if let error = errorFrom(query: query) {
            throw error
        }
        
        guard query["state"] == state else {
            throw RedirectError.invalidState(query["state"])
        }
        
        guard let code = query["code"] else {
            throw RedirectError.missingAuthorizationCode
        }
        
        return code
    }
    
    /// Convenience function that extracts an OAuth2 server error from a URL
    /// - Parameters:
    ///   - redirectUri: Redirect URI to match against.
    /// - Returns: Server error, if one is present.
    public func oauth2ServerError(redirectUri: URL? = nil) throws -> OAuth2ServerError? {
        let query = try oauth2QueryComponents(redirectUri: redirectUri)
        return errorFrom(query: query)
    }
}
