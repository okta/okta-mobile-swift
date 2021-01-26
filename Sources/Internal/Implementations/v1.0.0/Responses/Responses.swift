//
//  Responses.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-15.
//

import Foundation

enum IDXIONObjectType {
    case Link
}

protocol IDXIONObject: Decodable {
    var type: IDXIONObjectType { get }
}

extension IDXClient.APIVersion1 {
    struct OAuth2Error: Codable {
        let error: String
        let errorDescription: String?
        let errorUri: String?
    }

    struct IDXError: Codable {
        let error: String
        let errorDescription: String?
        let errorUri: String?
        let interactionHandle: String
    }

    struct InteractRequest: HasOAuthHTTPHeaders {}
    
    struct IntrospectRequest: HasIDPHTTPHeaders {
        let requestBody: RequestBody
    }
    
    struct TokenRequest: HasOAuthHTTPHeaders {
        let method: String
        let href: URL
        let accepts: AcceptType
        let parameters: [String:Any]
    }
    
    struct RemediationRequest {
        let method: String
        let href: URL
        let accepts: AcceptType
        let parameters: [String:Any]
    }

    class Response: NSObject, Decodable {
        let stateHandle: String
        let version: String
        let expiresAt: Date
        let intent: String
        let remediation: IonCollection<Form>?
        let messages: IonCollection<Message>?
        let authenticators: IonCollection<Authenticator>?
        let authenticatorEnrollments: IonCollection<AuthenticatorEnrollment>?
        let currentAuthenticatorEnrollment: IonObject<CurrentAuthenticatorEnrollment>?
        let currentAuthenticator: IonObject<CurrentAuthenticator>?
        let user: IonObject<User>?
        let app: IonObject<App>?
        let successWithInteractionCode: Form?
        let cancel: Form
        
        struct IonObject<T>: Decodable where T: Decodable {
            let type: String?
            let value: T
        }

        struct IonCollection<T>: Decodable where T: Decodable {
            let type: String?
            let value: [T]
        }

        struct User: Decodable {
            let id: String
        }
        
        struct App: Decodable {
            let id: String
            let label: String
            let name: String
        }
        
        struct Authenticator: Decodable {
            let displayName: String
            let id: String
            let type: String
            let methods: [[String:String]]
        }
        
        struct AuthenticatorEnrollment: Decodable {
            let displayName: String
            let id: String
            let type: String
            let methods: [[String:String]]
            let profile: [String:String]?
        }
        
        struct CurrentAuthenticator: Decodable {
            let displayName: String
            let id: String
            let type: String
            let methods: [[String:String]]
            let contextualData: [String:JSONValue]?
        }
        
        struct CurrentAuthenticatorEnrollment: Decodable {
            let displayName: String
            let id: String
            let type: String
            let methods: [[String:String]]
            let profile: [String:String]?
            let send: Form?
            let resend: Form?
            let poll: Form?
            let recover: Form?
        }
        
        struct Form: Decodable {
            let rel: [String]
            let name: String
            let method: String
            let href: URL
            let value: [FormValue]
            let accepts: String
            let relatesTo: [String]?
            let refresh: Double?
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
            let i18n: Localization
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
                i18n = try container.decode(Localization.self, forKey: .i18n)
                message = try container.decode(String.self, forKey: .message)
            }
        }
        
    }
    
    /// Internal OIE API v1.0.0 token response.
    final class Token: NSObject, Decodable {
        let tokenType: String
        let expiresIn: Int  // TODO: Do we need to represent the token expiration using a combination of the `expires_in` duration and the HTTP Date header field?
        let accessToken: String
        let scope: String
        let refreshToken: String?
        let idToken: String?
    }
}
