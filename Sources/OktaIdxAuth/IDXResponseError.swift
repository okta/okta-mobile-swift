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
import AuthFoundation

/// Describes an error reported from the server.
public struct IDXServerError: Error, LocalizedError {
    /// The description of the error message.
    public let message: String
    
    /// The localization key to uniquely identify this message.
    public let localizationKey: String?
    
    /// The severity of the error.
    public let severity: Response.Message.Severity
    
    @_documentation(visibility: internal)
    public var errorDescription: String? { message }
}

protocol ReturnsIDXError: APIParsingContext {}
extension ReturnsIDXError {
    func error(from data: Data) -> (any Error)? {
        guard let response = try? idxResponseDecoder().decode(IonResponse.self, from: data),
              let message = response.messages?.value.first
        else {
            return nil
        }
        
        return IDXServerError(message: message.message,
                              localizationKey: message.i18n?.key,
                              severity: Response.Message.Severity(string: message.type))
    }
}
