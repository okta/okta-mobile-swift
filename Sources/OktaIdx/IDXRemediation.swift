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

extension IDXClient {
    /// Instances of `IDXClient.Remediation` describe choices the user can make to proceed through the authentication workflow.
    ///
    /// Either simple or complex authentication scenarios consist of a set of steps that may be followed, but at some times the user may have a choice in what they use to verify their identity. For example, a user may have multiple choices in verifying their account, such as:
    ///
    /// 1. Password
    /// 2. Security Questions
    /// 3. Email verification
    /// 4. Other, customizable, verification steps.
    ///
    /// Each of the remediation options includes details about what form values should be collected from the user, and a description of the resulting request that should be sent to Okta to proceed to the next step.
    ///
    /// Nested form values can be accessed through keyed subscripting, for example:
    ///
    ///    response.remediations[.identifier]
    @objc(IDXRemediation)
    @dynamicMemberLookup
    public class Remediation: NSObject {
        /// The type of this remediation, which is used for keyed subscripting from a `IDXClient.RemediationCollection`.
        @objc public let type: RemediationType
        
        /// The string name for this type.
        @objc public let name: String

        /// A description of the form values that this remediation option supports and expects.
        @objc public let form: Form
        
        /// The set of authenticators associated with this remediation.
        @objc public internal(set) var authenticators: AuthenticatorCollection = .init(authenticators: nil)

        /// Returns the field within this remedation with the given name or key-path.
        ///
        /// To retrieve nested fields, keyPath "." notation can be used to select fields within child forms, for example:
        ///
        ///    response.remediations[.identifier]["credentials.passcode"]
        @objc public subscript(name: String) -> Form.Field? {
            get { form[name] }
        }
        
        public subscript(dynamicMember name: String) -> Form.Field? {
            form[dynamicMember: name]
        }
        
        /// Collection of messages for all fields within this remedation.
        @objc public lazy var messages: MessageCollection = {
            MessageCollection(messages: nil, nestedMessages: nestedMessages())
        }()
        
        private weak var client: IDXClientAPI?
        
        let method: String
        let href: URL
        let accepts: String?
        let refresh: TimeInterval?
        let relatesTo: [String]?

        internal init(client: IDXClientAPI,
                      name: String,
                      method: String,
                      href: URL,
                      accepts: String?,
                      form: Form,
                      refresh: TimeInterval? = nil,
                      relatesTo: [String]? = nil)
        {
            self.client = client
            self.name = name
            self.type = .init(string: name)
            self.method = method
            self.href = href
            self.accepts = accepts
            self.form = form
            self.refresh = refresh
            self.relatesTo = relatesTo
            
            super.init()
        }
        
        /// Executes the remediation option and proceeds through the workflow using the supplied form parameters.
        ///
        /// This method is used to proceed through the authentication flow, using the data assigned to the nested fields' `value` to make selections.
        /// - Important:
        /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didReceive:)` methods to process any response or error returned from this call.
        /// - Parameters:
        ///   - completion: Optional completion handler invoked when a response is received.
        ///   - response: `IDXClient.Response` object describing the next step in the remediation workflow, or `nil` if an error occurred.
        ///   - error: A description of the error that occurred, or `nil` if the request was successful.
        @objc
        public func proceed(completion: IDXClient.ResponseResult?) {
            guard let client = client else {
                completion?(nil, IDXClientError.invalidClient)
                return
            }
            
            client.proceed(remediation: self, completion: completion)
        }
        
        /// Remediation subclass used to represent social authentication remediations (e.g. IDP authentication).
        @objc(IDXSocialAuthRemediation)
        public class SocialAuth: Remediation {
            /// The URL an application should load or redirect to in order to continue authentication with the IDP service.
            @objc public var redirectUrl: URL { href }
            
            /// The service for this social authentication remediation.
            @objc public let service: Service

            /// The developer-assigned IDP name within the Okta admin dashboard.
            @objc public let idpName: String
            
            init(client: IDXClientAPI,
                 name: String,
                 method: String,
                 href: URL,
                 accepts: String?,
                 form: IDXClient.Remediation.Form,
                 refresh: TimeInterval?,
                 relatesTo: [String]?,
                 id: String,
                 idpName: String,
                 service: Service)
            {
                self.idpName = idpName
                self.service = service
                
                super.init(client: client,
                           name: name,
                           method: method,
                           href: href,
                           accepts: accepts,
                           form: form,
                           refresh: refresh,
                           relatesTo: relatesTo)
            }
            
            /// The list of services that are possible within a social authentication workflow.
            @objc(IDXSocialAuthRemediationService)
            public enum Service: Int {
            case facebook
            case google
            case linkedin
            case other
            }
        }
    }
}
