/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

enum IDXIONObjectType {
    case Link
}

protocol IDXIONObject: Decodable {
    var type: IDXIONObjectType { get }
}

protocol IDXIONRelatable {
    var relatableIdentifier: String? { get }
}

extension IDXClient.APIVersion1 {
    struct OAuth2Error: Codable, Error, LocalizedError {
        let errorSummary: String
        let errorCode: String?
        let errorUri: String?
        let errorLink: String?
        let errorId: String?
        
        var errorDescription: String? {
            errorSummary
        }
    }

    struct IDXError: Codable {
        let error: String
        let errorDescription: String?
        let errorUri: String?
        let interactionHandle: String
    }

    struct InteractRequest: HasOAuthHTTPHeaders {
        let state: String
        let codeChallenge: String
    }
    
    struct IntrospectRequest: HasIDPHTTPHeaders {
        let requestBody: RequestBody
    }
    
    struct TokenRequest: HasOAuthHTTPHeaders {
        let method: String
        let href: URL
        let accepts: AcceptType
        let parameters: [String:Any]
    }
    
    struct RevokeRequest: HasOAuthHTTPHeaders {
        let token: String
        let tokenTypeHint: String
    }
    
    struct RemediationRequest: HasHTTPHeaders {
        let method: String
        let href: URL
        let accepts: AcceptType
        let parameters: [String:Any]
    }

    final class Response: NSObject, Decodable {
        let stateHandle: String?
        let version: String
        let expiresAt: Date?
        let intent: String?
        let remediation: IonCollection<Form>?
        let messages: IonCollection<Message>?
        let authenticators: IonCollection<Authenticator>?
        let authenticatorEnrollments: IonCollection<Authenticator>?
        let currentAuthenticatorEnrollment: IonObject<Authenticator>?
        let currentAuthenticator: IonObject<Authenticator>?
        let recoveryAuthenticator: IonObject<Authenticator>?
        let user: IonObject<User>?
        let app: IonObject<App>?
        let successWithInteractionCode: Form?
        let cancel: Form?
        
        struct IonObject<T>: Decodable where T: Decodable {
            let type: String?
            let value: T
        }

        struct IonCollection<T>: Decodable where T: Decodable {
            let type: String?
            let value: [T]
        }
        
        struct User: Decodable {
            let id: String?
        }
        
        struct App: Decodable {
            let id: String
            let label: String
            let name: String
        }
        
        struct Authenticator: Decodable, IDXIONRelatable {
            let displayName: String?
            let id: String?
            let type: String
            let key: String?
            let methods: [[String:String]]?
            let settings: [String:JSONValue]?
            let contextualData: [String:JSONValue]?
            let profile: [String:String]?
            let send: Form?
            let resend: Form?
            let poll: Form?
            let recover: Form?
            
            var relatableIdentifier: String? { id }
            var jsonPath: String?
        }
        
        struct Form: Decodable {
            let rel: [String]?
            let name: String
            let method: String
            let href: URL
            let value: [FormValue]?
            let accepts: String?
            let relatesTo: [String]?
            let refresh: Double?
            let type: String?
            let idp: [String:String]?
        }
        
        struct CompositeForm: Decodable {
            let form: CompositeFormValue
        }
        
        struct CompositeFormValue: Decodable {
            let value: [FormValue]
        }
        
        struct FormValue: Decodable {
            let id: String?
            let name: String?
            let label: String?
            let type: String?
            let value: JSONValue?
            let required: Bool?
            let secret: Bool?
            let visible: Bool?
            let mutable: Bool?
            let form: CompositeFormValue?
            let options: [FormValue]?
            let relatesTo: String?
            let messages: IonCollection<Message>?
            
            private enum CodingKeys: String, CodingKey {
                case id, name, required, label, type, value, secret, visible, mutable, options, form, relatesTo, messages
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                id = try container.decodeIfPresent(String.self, forKey: .id)
                name = try container.decodeIfPresent(String.self, forKey: .name)
                label = try container.decodeIfPresent(String.self, forKey: .label)
                type = try container.decodeIfPresent(String.self, forKey: .type)
                required = try container.decodeIfPresent(Bool.self, forKey: .required)
                secret = try container.decodeIfPresent(Bool.self, forKey: .secret)
                visible = try container.decodeIfPresent(Bool.self, forKey: .visible)
                mutable = try container.decodeIfPresent(Bool.self, forKey: .mutable)
                relatesTo = try container.decodeIfPresent(String.self, forKey: .relatesTo)
                options = try container.decodeIfPresent([FormValue].self, forKey: .options)
                messages = try container.decodeIfPresent(IonCollection<Message>.self, forKey: .messages)

                let formObj = try? container.decodeIfPresent(CompositeFormValue.self, forKey: .form)
                let valueAsCompositeObj = try? container.decodeIfPresent(CompositeForm.self, forKey: .value)
                let valueAsJsonObj = try? container.decodeIfPresent(JSONValue.self, forKey: .value)
                
                if formObj == nil && valueAsCompositeObj != nil {
                    form = valueAsCompositeObj?.form
                } else {
                    form = formObj
                }
                
                if let valueAsCompositeObj = valueAsCompositeObj {
                    value = .object(valueAsCompositeObj)
                } else {
                    value = valueAsJsonObj
                }
            }
        }
        
        struct Message: Codable {
            let type: String
            let i18n: Localization?
            let message: String

            struct Localization: Codable {
                let key: String
            }
            
            private enum CodingKeys: String, CodingKey {
                case type = "class", i18n, message
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                type = try container.decode(String.self, forKey: .type)
                i18n = try container.decodeIfPresent(Localization.self, forKey: .i18n)
                message = try container.decode(String.self, forKey: .message)
            }
        }
        
    }
    
    /// Internal OIE API v1.0.0 token response.
    final class Token: NSObject, Decodable {
        let tokenType: String
        let expiresIn: Int
        let accessToken: String
        let scope: String
        let refreshToken: String?
        let idToken: String?
    }

    struct Redirect {
        enum Query {
            enum Key {
                static let interactionCode = "interaction_code"
                static let state = "state"
                static let error = "error"
                static let errorDescription = "error_description"
            }
            
            enum Value {
                static let interactionRequired = "interaction_required"
            }
        }
        
        let url: URL
        let scheme: String
        let path: String
        
        let interactionCode: String?
        let state: String?
        let error: String?
        let errorDescription: String?
        
        let interactionRequired: Bool
        
        init?(url: String) {
            guard let url = URL(string: url) else {
                return nil
            }
            
            self.init(url: url)
        }

        init?(url: URL) {
            self.url = url
            
            guard let urlComponents = URLComponents(string: url.absoluteString),
                  let scheme = urlComponents.scheme else
            {
                return nil
            }

            self.scheme = scheme
            self.path = urlComponents.path
            
            let queryItems = urlComponents.queryItems
            
            let queryValue: (String) -> String? = { name in
                queryItems?.first { $0.name == name }?.value?.removingPercentEncoding
            }

            self.interactionCode = queryValue(Query.Key.interactionCode)
            self.state = queryValue(Query.Key.state)
            
            self.error = queryValue(Query.Key.error)
            self.errorDescription = queryValue(Query.Key.errorDescription)
            self.interactionRequired = (self.error == Query.Value.interactionRequired)
        }
    }
}
