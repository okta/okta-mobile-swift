//
//  IDXClient+Response.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-15.
//

import Foundation

public extension IDXClient {
    /// Describes the response from an Okta Identity Engine workflow stage. This is used to determine the current state of the workflow, the set of available remediation steps to proceed through the workflow, actions that can be performed, and other information relevant to the authentication of a user.
    @objc(IDXResponse)
    final class Response: NSObject {
        private let client: IDXClientAPIImpl
        
        /// The current state handle for the IDX workflow.
        public let stateHandle: String
        
        /// The API version used.
        public let version: String
        
        /// The date at which this stage of the workflow expires, after which the authentication process should be restarted.
        public let expiresAt: Date
        
        /// A string describing the intent of the workflow, e.g. "LOGIN".
        public let intent: String
        
        /// An object describing the sort of remediation steps available to the user, or `nil` if the workflow is ended.
        public let remediation: Remediation?
        
        /// Indicates whether or not the user has logged in successfully. If this is `true`, this response object should be exchanged for access tokens utilizing the `exchangeCode` method.
        public var isLoginSuccessful: Bool {
            return successResponse != nil
        }
        
        /// Cancels the current workflow.
        /// - Parameters:
        ///   - completion: Invoked when the operation is cancelled.
        ///   - response: The response describing the new workflow next steps, or `nil` if an error occurred.
        ///   - error: Describes the error that occurred, or `nil` if successful.
        public func cancel(completionHandler: @escaping(_ response: Response?, _ error: Error?) -> Void) {
            guard let cancelOption = cancelRemediationOption else {
                completionHandler(nil, IDXClientError.unknownRemediationOption(name: "cancel"))
                return
            }
            
            cancelOption.proceed(with: [:], completionHandler: completionHandler)
        }
        
        /// Exchanges the successful remediation response with a token.
        /// - Parameters:
        ///   - successResponse: Successful remediation option to exchange.
        ///   - completion: Completion handler invoked when a token, or error, is received.
        ///   - token: The token that was exchanged, or `nil` if an error occurred.
        ///   - error: Describes the error that occurred, or `nil` if successful.
        public func exchangeCode(completionHandler: @escaping(_ token: Token?, _ error: Error?) -> Void) {
            guard let successResponse = successResponse else {
                completionHandler(nil, IDXClientError.successResponseMissing)
                return
            }
            
            client.exchangeCode(using: successResponse, completion: completionHandler)
        }
        
        internal let cancelRemediationOption: Remediation.Option?
        internal let successResponse: Remediation.Option?
        internal init(client: IDXClientAPIImpl, stateHandle: String, version: String, expiresAt: Date, intent: String, remediation: Remediation?, cancel: Remediation.Option?, success: Remediation.Option?) {
            self.client = client
            self.stateHandle = stateHandle
            self.version = version
            self.expiresAt = expiresAt
            self.intent = intent
            self.remediation = remediation
            self.cancelRemediationOption = cancel
            self.successResponse = success
            
            super.init()
        }
    }
    
    /// Access tokens created as a result of exchanging a successful workflow response.
    @objc(IDXToken)
    final class Token: NSObject {
        /// The access token to use.
        public let accessToken: String
        
        /// The refresh token, if available.
        public let refreshToken: String?
        
        /// The time interval after which this token will expire.
        public let expiresIn: TimeInterval
        
        /// The ID token JWT string.
        public let idToken: String?
        
        /// The access scopes for this token.
        public let scope: String
        
        /// The type of this token.
        public let tokenType: String

        internal init(accessToken: String,
                      refreshToken: String?,
                      expiresIn: TimeInterval,
                      idToken: String?,
                      scope: String,
                      tokenType: String)
        {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.expiresIn = expiresIn
            self.idToken = idToken
            self.scope = scope
            self.tokenType = tokenType
            
            super.init()
        }
    }

    /// The `IDXClient.Remediation` object describes the remediation steps the user, and application, can follow to proceed through the workflow.
    @objc(IDXRemediation)
    final class Remediation: NSObject {
        /// The remediation type, described in the response payload.
        public var type: String // TODO: Is this really necessary? Is it every not `array`?
        
        /// The array of remediation options available to the developer to proceed through the authentication workflow.
        public let remediationOptions: [Option]
        
        private weak var client: IDXClientAPIImpl?

        internal init(client: IDXClientAPIImpl, type: String, remediationOptions: [Option]) {
            self.client = client
            self.type = type
            self.remediationOptions = remediationOptions
         
            super.init()
        }
        
        /// Describes an individual value within a form, used to collect and submit information from the user to proceed through the authentication workflow.
        @objc(IDXFormValue)
        final public class FormValue: NSObject {
            /// The programmatic name for this form value.
            public let name: String?
            
            /// The user-readable label describing this form value.
            public let label: String?
            
            /// The type of value expected from the client.
            public let type: String?
            
            /// The value to send, if a default is provided from the Identity Engine.
            public let value: AnyObject?
            
            /// Indicates if the form value is intended to be seen by the user.
            public let visible: Bool
            
            /// Indicates whether or not the form value is read-only.
            public let mutable: Bool
            
            /// Indicates whether or not the form value is required to successfully proceed through this remediation option.
            public let required: Bool
            
            /// Indicates whether or not the value supplied in this form value should be considered secret, and not presented to the user.
            public let secret: Bool
            
            /// For composite form fields, this contains the nested array of form values to group together.
            public let form: [FormValue]?
            
            /// For form fields that have specific options the user can choose from (e.g. security question, passcode, etc), this indicates the different form options that should be displayed to the user.
            public let options: [FormValue]?
            
            public func relatesTo() -> AnyObject? {
                return nil
            }
            
            internal init(name: String?,
                          label: String?,
                          type: String?,
                          value: AnyObject?,
                          visible: Bool,
                          mutable: Bool,
                          required: Bool,
                          secret: Bool,
                          form: [FormValue]?,
                          options: [FormValue]?)
            {
                self.name = name
                self.label = label
                self.type = type
                self.value = value
                self.visible = visible
                self.mutable = mutable
                self.required = required
                self.secret = secret
                self.form = form
                self.options = options
                
                super.init()
            }
        }

        /// Instances of `IDXClient.Remediation.Option` describe choices the user can make to proceed through the authentication workflow.
        ///
        /// Either simple or complex authentication scenarios consist of a set of steps that may be followed, but at some times the user may have a choice in what they use to verify their identity. For example, a user may have multiple choices in verifying their account, such as:
        ///
        /// 1. Password
        /// 2. Security Questions
        /// 3. Email verification
        /// 4. Other, customizable, verification steps.
        ///
        /// Each of the remediation options includes details about what form values should be collected from the user, and a description of the resulting request that should be sent to Okta to proceed to the next step.
        @objc(IDXRemediationOption)
        final public class Option: NSObject {
            public let rel: [String] // TODO: Is this necessary to expose to the developer?

            /// The name of this remediation step, which can be used to control how the form is presented to the user.
            public let name: String
            public let method: String // TODO: Are method, href, accepts, etc necessary to the developer if they're using our SDK? Those should be internal implementation details. The developer can't really do anything with this information after all.
            public let href: URL
            public let accepts: String
            
            /// A description of the form values that this remediation option supports and expects.
            public let form: [FormValue]
            
            private weak var client: IDXClientAPIImpl?

            internal init(client: IDXClientAPIImpl,
                          rel: [String],
                          name: String,
                          method: String,
                          href: URL,
                          accepts: String,
                          form: [FormValue])
            {
                self.client = client
                self.rel = rel
                self.name = name
                self.method = method
                self.href = href
                self.accepts = accepts
                self.form = form
                
                super.init()
            }
            
            /// Executes the remediation option and proceeds through the workflow using the supplied form parameters.
            /// - Parameters:
            ///   - dataFromUI: Form data collected from the user.
            ///   - completionHandler: Completion handler invoked when a response is received.
            ///   - response: `IDXClient.Response` object describing the next step in the remediation workflow, or `nil` if an error occurred.
            ///   - error: A description of the error that occurred, or `nil` if the request was successful.
            public func proceed(with dataFromUI: [String:Any], completionHandler: @escaping (_ response: Response?, _ error: Error?) -> Void) {
                guard let client = client else {
                    completionHandler(nil, IDXClientError.invalidClient)
                    return
                }
                
                client.proceed(remediation: self, data: dataFromUI, completion: completionHandler)
            }
            
            /// Apply the remediation option parameters, reconciling default values and mutability requirements.
            /// - Parameter params: Optional parameters supplied by the user.
            /// - Throws::
            ///   - IDXClientError.invalidParameter
            ///   - IDXClientError.parameterImmutable
            ///   - IDXClientError.missingRequiredParameter
            /// - Returns: Dictionary of key/value pairs to send to the remediation endpoint
            internal func formValues(with params: [String:Any]? = nil) throws -> [String:Any] {
                var result: [String:Any] = form
                    .filter { $0.value != nil && $0.name != nil }
                    .reduce(into: [:]) { (result, formValue) in
                    result[formValue.name!] = formValue.value
                }
                
                let allFormValues = form.reduce(into: [String:FormValue]()) { (result, value) in
                    result[value.name] = value
                }
                
                try params?.forEach { (key, value) in
                    guard let formValue = allFormValues[key] else {
                        throw IDXClientError.invalidParameter(name: key)
                    }
                    
                    guard formValue.mutable == true else {
                        throw IDXClientError.parameterImmutable(name: key)
                    }
                    
                    result[key] = value
                }
                
                try allFormValues.values.filter { $0.required }.forEach {
                    /// TODO: Fix compound field support and relatesTo
                    guard result[$0.name!] != nil else {
                        throw IDXClientError.missingRequiredParameter(name: $0.name!)
                    }
                }
                
                return result
            }
        }
    }
}
