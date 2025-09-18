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

enum IDXIONObjectType: Sendable {
    case Link
}

protocol IDXIONObject: Decodable {
    var type: IDXIONObjectType { get }
}

protocol IDXIONRelatable {
    var relatableIdentifier: String? { get }
}

struct IDXOAuth2Error: Sendable, Codable, Error, LocalizedError {
    let errorSummary: String
    let errorCode: String?
    let errorUri: String?
    let errorLink: String?
    let errorId: String?
    
    var errorDescription: String? {
        errorSummary
    }
}

struct IDXError: Sendable, Codable {
    let error: String
    let errorDescription: String?
    let errorUri: String?
    let interactionHandle: String
}

final class IonResponse: Sendable, Decodable, JSONDecodable, IDXResponse {
    let stateHandle: String?
    let version: String
    let expiresAt: Date?
    let intent: String?
    let remediation: IonCollection<IonForm>?
    let messages: IonCollection<IonMessage>?
    let authenticators: IonCollection<IonAuthenticator>?
    let authenticatorEnrollments: IonCollection<IonAuthenticator>?
    let currentAuthenticatorEnrollment: IonObject<IonAuthenticator>?
    let currentAuthenticator: IonObject<IonAuthenticator>?
    let recoveryAuthenticator: IonObject<IonAuthenticator>?
    let webauthnAutofillUIChallenge: IonObject<IonChallengeData>?
    let user: IonObject<IonUser>?
    let app: IonObject<IonApp>?
    let successWithInteractionCode: IonForm?
    let cancel: IonForm?

    static var jsonDecoder: JSONDecoder {
        idxResponseDecoder()
    }
}

struct IonObject<T: Sendable & Decodable>: Sendable, Decodable, IDXResponse {
    let type: String?
    let value: T
}

struct IonCollection<T: Sendable & Decodable>: Sendable, Decodable, IDXResponse {
    let type: String?
    let value: [T]
}

struct IonUser: Sendable, Decodable, IDXResponse {
    let id: String?
    let profile: [String: String?]?
    let identifier: String?
}

struct IonApp: Sendable, Decodable, IDXResponse {
    let id: String
    let label: String
    let name: String
}

struct IonChallengeData: Sendable, Decodable, IDXResponse {
    let challengeData: JSON.Value
}

struct IonAuthenticator: Sendable, Decodable, IDXIONRelatable, IDXResponse {
    let displayName: String?
    let id: String?
    let type: Authenticator.Kind
    let key: String?
    let methods: [[String: String]]?
    let settings: JSON.Value?
    let contextualData: [String: JSON.Value]?
    let profile: [String: String]?
    let send: IonForm?
    let resend: IonForm?
    let poll: IonForm?
    let recover: IonForm?
    
    var relatableIdentifier: String? { id }
    var jsonPath: String?
}

struct IonForm: Sendable, Decodable, IDXResponse {
    let rel: [String]?
    let name: String
    let method: APIRequestMethod
    let href: URL
    let value: [IonFormValue]?
    let accepts: APIContentType?
    let relatesTo: [String]?
    let refresh: Double?
    let type: String?
    let idp: [String: String]?
}

struct IonCompositeForm: Sendable, Decodable, IDXResponse {
    let form: IonCompositeFormValue
}

struct IonCompositeFormValue: Sendable, Decodable, IDXResponse {
    let value: [IonFormValue]
}

struct IonFormValue: Sendable, Decodable, IDXResponse {
    enum Value: Sendable {
        case json(JSON.Value)
        case compositeForm(IonCompositeForm)
    }
    let id: String?
    let name: String?
    let label: String?
    let type: String?
    let value: JSON.Value
    let valueAsCompositeForm: IonCompositeForm?
    let required: Bool?
    let secret: Bool?
    let visible: Bool?
    let mutable: Bool?
    let form: IonCompositeFormValue?
    let options: [IonFormValue]?
    let relatesTo: String?
    let messages: IonCollection<IonMessage>?

    private enum CodingKeys: String, CodingKey {
        case id, name, required, label, type, value, secret, visible, mutable, options, form, relatesTo, messages
    }
    
    init(from decoder: any Decoder) throws {
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
        options = try container.decodeIfPresent([IonFormValue].self, forKey: .options)
        messages = try container.decodeIfPresent(IonCollection<IonMessage>.self, forKey: .messages)
        
        let formObj = try? container.decodeIfPresent(IonCompositeFormValue.self, forKey: .form)
        valueAsCompositeForm = try? container.decodeIfPresent(IonCompositeForm.self, forKey: .value)
        value = try container.decodeIfPresent(JSON.Value.self, forKey: .value) ?? .null
        
        if formObj == nil && valueAsCompositeForm != nil {
            form = valueAsCompositeForm?.form
        } else {
            form = formObj
        }
    }
}

struct IonMessage: Sendable, Codable, IDXResponse {
    let type: String
    let i18n: IonLocalization?
    let message: String
    
    struct IonLocalization: Codable {
        let key: String
    }
    
    private enum CodingKeys: String, CodingKey {
        case type = "class", i18n, message
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        i18n = try container.decodeIfPresent(IonLocalization.self, forKey: .i18n)
        message = try container.decode(String.self, forKey: .message)
    }
}

/// Internal OIE API v1.0.0 token response.
final class IonToken: NSObject, Decodable, IDXResponse {
    let tokenType: String
    let expiresIn: Int
    let accessToken: String
    let scope: String
    let refreshToken: String?
    let idToken: String?
}
