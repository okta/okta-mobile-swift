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
        let remediation: FormCollection?
//        let messages: Messages
//        let authenticatorEnrollments: AuthenticatorEnrollments
//        let currentAuthenticatorEnrollment: FormCollection?
//        let user: User
        let app: FormObject
        let successWithInteractionCode: Form?
        let cancel: Form
        
        struct FormObject: Decodable {
            let type: String
            let value: FormValue
        }

        struct FormCollection: Decodable {
            let type: String
            let value: [Form]
        }

        struct Form: Decodable {
            let rel: [String]
            let name: String
            let method: String
            let href: URL
            let value: [FormValue]
            let accepts: String
            let relatesTo: [String]?
        }
        
        struct CompositeForm: Decodable {
            let form: CompositeFormValue
        }
        
        struct CompositeFormValue: Decodable {
            let value: [FormValue]
        }
        
        struct FormValue: Decodable {
            let name: String?
            let label: String?
            let type: String?
            let value: JSONValue?
            let required: Bool?
            let secret: Bool?
            let visible: Bool?
            let mutable: Bool?
            let options: [FormValue]?
            let relatesTo: String?
            
            private enum CodingKeys: String, CodingKey {
                case name, required, label, type, value, secret, visible, mutable, options, relatesTo
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                name = try container.decodeIfPresent(String.self, forKey: .name)
                label = try container.decodeIfPresent(String.self, forKey: .label)
                type = try container.decodeIfPresent(String.self, forKey: .type)
                required = try container.decodeIfPresent(Bool.self, forKey: .required)
                secret = try container.decodeIfPresent(Bool.self, forKey: .secret)
                visible = try container.decodeIfPresent(Bool.self, forKey: .visible)
                mutable = try container.decodeIfPresent(Bool.self, forKey: .mutable)
                relatesTo = try container.decodeIfPresent(String.self, forKey: .relatesTo)
                options = try container.decodeIfPresent([FormValue].self, forKey: .options)
                
                if let obj = try? container.decodeIfPresent(CompositeForm.self, forKey: .value) {
                    value = .object(obj)
                } else {
                    value = try? container.decodeIfPresent(JSONValue.self, forKey: .value)
                }
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
