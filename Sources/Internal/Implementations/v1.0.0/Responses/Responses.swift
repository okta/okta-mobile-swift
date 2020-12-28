//
//  Responses.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-15.
//

import Foundation

extension IDXClient.APIVersion1 {
    struct InteractRequest: HasOAuthHTTPHeaders {}
    
    struct IntrospectRequest: HasIDPHTTPHeaders {
        let requestBody: RequestBody
    }
    
    struct TokenRequest: HasOAuthHTTPHeaders {}
    
    struct IdentifyRequest: HasIDPHTTPHeaders {
        let stateHandle: String
        let identifier: String
        let credentials: IDXClient.Credentials
        let rememberMe: Bool
    }
    
    struct EnrollRequest: HasIDPHTTPHeaders {
        let stateHandle: String
        let authenticator: IDXClient.Authenticator
    }
    
    struct ChallengeRequest: HasIDPHTTPHeaders {
        let stateHandle: String
        let authenticator: IDXClient.Authenticator
    }
    
    struct AnswerChallengeRequest: HasIDPHTTPHeaders {
        let stateHandle: String
        let credentials: IDXClient.Credentials
    }
    
    struct CancelRequest: HasIDPHTTPHeaders {
        let stateHandle: String
    }
    
    struct RemediationRequest {
        let method: String
        let href: URL
        let accepts: AcceptType
        let parameters: [String:Any]
    }

    class Response: NSObject, Codable {
        let stateHandle: String
        let version: String
        let expiresAt: Date
        let intent: String
        let remediation: FormCollection
//        let messages: Messages
//        let authenticatorEnrollments: AuthenticatorEnrollments
//        let currentAuthenticatorEnrollment: FormCollection?
//        let user: User
        let app: FormObject
//        let successWithInteractionCode: SuccessResponse
        let cancel: Form
        
        struct FormObject: Codable {
            let type: String
            let value: FormValue
        }

        struct FormCollection: Codable {
            let type: String
            let value: [Form]
        }

        struct Form: Codable {
            let rel: [String]
            let name: String
            let method: String
            let href: URL
            let value: [FormValue]
            let accepts: String
            let relatesTo: [String]?
        }
        
        struct FormValue: Codable {
            let name: String
            let required: Bool?
            let label: String?
            let type: String?
            let value: JSONValue?
            let secret: Bool?
            let visible: Bool?
            let mutable: Bool?
            let options: [FormValue]?
            let relatesTo: String?
        }
    }
}
