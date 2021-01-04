//
//  IDXClient+Response.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-15.
//

import Foundation

public extension IDXClient {
    @objc(IDXResponse)
    class Response: NSObject {
        private weak var client: IDXClientAPIImpl?
        
        public let stateHandle: String
        public let version: String
        public let expiresAt: Date
        public let intent: String
        public let remediation: Remediation?
        public var isLoginSuccessful: Bool {
            return successResponse != nil
        }
        
        internal let cancelRemediationOption: Remediation.Option?
        internal let successResponse: Remediation.Option?
        
        internal init(client: IDXClientAPIImpl?, stateHandle: String, version: String, expiresAt: Date, intent: String, remediation: Remediation?, cancel: Remediation.Option?, success: Remediation.Option?) {
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
        
        public func cancel(completionHandler: @escaping(Response?, Error?) -> Void) {
            guard let cancelOption = cancelRemediationOption else {
                completionHandler(nil, IDXClientError.unknownRemediationOption(name: "cancel"))
                return
            }
            
            cancelOption.proceed(with: [:], completionHandler: completionHandler)
        }
        
        public func exchangeCode(completionHandler: @escaping(Token?, Error?) -> Void) {
            guard let successResponse = successResponse else {
                completionHandler(nil, IDXClientError.successResponseMissing)
                return
            }
            
            guard let client = client else {
                completionHandler(nil, IDXClientError.invalidClient)
                return
            }
            
            client.exchangeCode(using: successResponse, completion: completionHandler)
        }
    }
    
    @objc(IDXToken)
    class Token: NSObject {
        public let accessToken: String
        public let refreshToken: String?
        public let expiresIn: TimeInterval
        public let idToken: String?
        public let scope: String
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

    @objc(IDXRemediation)
    class Remediation: NSObject {
        public var type: String
        public let remediationOptions: [Option]
        
        private weak var client: IDXClientAPIImpl?

        internal init(client: IDXClientAPIImpl, type: String, remediationOptions: [Option]) {
            self.client = client
            self.type = type
            self.remediationOptions = remediationOptions
         
            super.init()
        }
        
        @objc(IDXFormValue)
        public class FormValue: NSObject {
            public let name: String?
            public let label: String?
            public let type: String?
            public let value: AnyObject?
            public let visible: Bool
            public let mutable: Bool
            public let required: Bool
            public let secret: Bool
            public let form: [FormValue]?
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

        @objc(IDXRemediationOption)
        public class Option: NSObject {
            public let rel: [String]
            public let name: String
            public let method: String
            public let href: URL
            public let accepts: String
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

            public func proceed(with dataFromUI: [String:Any], completionHandler: @escaping (Response?, Error?) -> Void) {
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
