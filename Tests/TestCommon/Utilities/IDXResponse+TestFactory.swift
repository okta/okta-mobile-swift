//
// Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import OktaIdx

extension IDXClient.Response {
    enum Option {
        case cancel
        case selectIdentify
        case identify
        case challengeAuthenticator(state: ChallengeState)
        case selectAuthenticatorAuthenticate(authenticators: [Authenticator])
        case successWithInteractionCode
        case skip
        
        enum ChallengeState {
            case normal
            case success
            case passwordError
        }
        
        enum Authenticator {
            case email
            case password
            case phone
        }
    }
    
    
    class Test: IDXClient.Response {
        init(client: IDXClientAPI,
             intent: IDXClient.Response.Intent = .login,
             with options: [Option])
        {
            let authenticators = [IDXClient.Authenticator]()
            var remediations = [IDXClient.Remediation]()
            var successRemediation: IDXClient.Remediation?
            let messages = [IDXClient.Message]()
            
            for option in options {
                switch option {
                case .cancel:
                    remediations.append(IDXClient.Remediation.Test(client: client,
                                                                   name: "cancel",
                                                                   method: "POST",
                                                                   href: URL(string: "https://example.com/idp/idx/cancel")!,
                                                                   accepts: "application/ion+json; okta-version=1.0.0",
                                                                   form: IDXClient.Remediation.Form([ .stateHandle ])))
                case .selectIdentify: break
                case .identify:
                    remediations.append(IDXClient.Remediation.Test(client: client,
                                                                   name: "identify",
                                                                   method: "POST",
                                                                   href: URL(string: "https://example.com/idp/idx/identify")!,
                                                                   accepts: "application/ion+json; okta-version=1.0.0",
                                                                   form: IDXClient.Remediation.Form([ .identifier, .rememberMe, .stateHandle ])))
                case .challengeAuthenticator(state: _):
                    remediations.append(IDXClient.Remediation.Test(client: client,
                                                                   name: "challenge-authenticator",
                                                                   method: "POST",
                                                                   href: URL(string: "https://example.com/idp/idx/identify")!,
                                                                   accepts: "application/ion+json; okta-version=1.0.0",
                                                                   form: IDXClient.Remediation.Form([ .identifier, .rememberMe, .stateHandle ])))
                case .successWithInteractionCode:
                    successRemediation = IDXClient.Remediation.Test(client: client,
                                                                    name: "issue",
                                                                    method: "POST",
                                                                    href: URL(string: "https://example.com/oauth2/blahblah/v1/token")!,
                                                                    accepts: "application/ion+json; okta-version=1.0.0",
                                                                    form: IDXClient.Remediation.Form(fields: [
                                                                        .init(name: "grant_type",
                                                                              value: "interaction_code" as AnyObject,
                                                                              visible: false,
                                                                              mutable: false,
                                                                              required: true,
                                                                              secret: false),
                                                                        .init(name: "interaction_code",
                                                                              value: "blahblahblah" as AnyObject,
                                                                              visible: false,
                                                                              mutable: false,
                                                                              required: true,
                                                                              secret: false),
                                                                        .init(name: "client_id",
                                                                              value: "clientId" as AnyObject,
                                                                              visible: false,
                                                                              mutable: false,
                                                                              required: true,
                                                                              secret: false),
                                                                        .init(name: "client_secret",
                                                                              visible: false,
                                                                              mutable: false,
                                                                              required: true,
                                                                              secret: false),
                                                                        .init(name: "code_verifier",
                                                                              visible: false,
                                                                              mutable: false,
                                                                              required: true,
                                                                              secret: false)
                                                                    ])!)
                    
                case .selectAuthenticatorAuthenticate(authenticators: _): break
                    
                case .skip:
                    remediations.append(IDXClient.Remediation.Test(client: client,
                                                                   name: "skip",
                                                                   method: "POST",
                                                                   href: URL(string: "https://example.com/idp/idx/skip")!,
                                                                   accepts: "application/ion+json; okta-version=1.0.0",
                                                                   form: IDXClient.Remediation.Form([ .stateHandle ])))
                }
            }
            
            super.init(client: client,
                       expiresAt: Date(),
                       intent: intent,
                       authenticators: .init(authenticators: authenticators),
                       remediations: .init(remediations: remediations),
                       successRemediationOption: successRemediation,
                       messages: .init(messages: messages),
                       app: nil,
                       user: nil)
        }
        
        func when(_ type: IDXClient.Remediation.RemediationType, send response: Test) -> Test {
            guard let remediation = remediations[type] as? IDXClient.Remediation.Test else { return self }
            remediation.proceedResponse = response
            return self
        }
        
        func when(_ type: IDXClient.Remediation.RemediationType, send error: Error) -> Test {
            guard let remediation = remediations[type] as? IDXClient.Remediation.Test else { return self }
            remediation.proceedError = error
            return self
        }
    }
}

extension IDXClient.Remediation {
    class Test: IDXClient.Remediation {
        fileprivate var proceedResponse: IDXClient.Response.Test?
        fileprivate var proceedError: Error?
        
        override func proceed(completion: IDXClient.ResponseResult?) {
            completion?(proceedResponse, proceedError)
        }
    }
}

extension IDXClient.Remediation.Form {
    convenience init(_ fields: [Field.TestField]) {
        self.init(fields: fields.map { Field($0) })!
    }
}

extension IDXClient.Token {
    static let success = IDXClient.Token(accessToken: "access",
                                         refreshToken: "refresh",
                                         expiresIn: 3600,
                                         idToken: nil,
                                         scope: "all",
                                         tokenType: "Bearer",
                                         configuration: .init(issuer: "issuer",
                                                              clientId: "clientId",
                                                              clientSecret: nil,
                                                              scopes: ["all"],
                                                              redirectUri: "redirect://uri"))
}

extension IDXClient.Remediation.Form.Field {
    enum TestField {
        case stateHandle, identifier, rememberMe, passcode, passwordCredentials
    }
    
    convenience init(_ type: TestField) {
        switch type {
        case .stateHandle:
            self.init(name: "stateHandle",
                      value: "ABC_easy_as_123" as AnyObject,
                      visible: false,
                      mutable: false,
                      required: true,
                      secret: false)
        case .identifier:
            self.init(name: "identifier",
                  label: "Username",
                  visible: true,
                  mutable: true,
                  required: false,
                  secret: false)
        case .rememberMe:
            self.init(name: "rememberMe",
                      label: "Remember this device",
                      type: "boolean",
                      visible: true,
                      mutable: true,
                      required: false,
                      secret: false)
        case .passcode:
            self.init(name: "passcode",
                      label: "Password",
                      visible: true,
                      mutable: true,
                      required: true,
                      secret: true)
        case .passwordCredentials:
            self.init(name: "credentials",
                      type: "object",
                      visible: true,
                      mutable: true,
                      required: true,
                      secret: true,
                      form: IDXClient.Remediation.Form([.passcode]))
        }
    }
}
