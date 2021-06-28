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

extension IDXClient.Remediation.Form {
    /// Describes an individual field within a form, used to collect and submit information from the user to proceed through the authentication workflow.
    ///
    /// Nested form values can be accessed through keyed subscripting, for example:
    ///
    ///    credentials.form["passcode"]
    @objc(IDXRemediationFormField)
    @dynamicMemberLookup
    final public class Field: NSObject {
        /// The programmatic name for this form value.
        @objc public let name: String?
        
        /// The user-readable label describing this form value.
        @objc public let label: String?
        
        /// The type of value expected from the client.
        @objc public let type: String?
        
        /// The value to send, if a default is provided from the Identity Engine.
        @nonobjc public var value: IDXFormValue? {
            get { _value as? IDXFormValue }
            set {
                guard isMutable else { return }
                _value = newValue as AnyObject
            }
        }
        
        @objc(value) public var objcValue: AnyObject? {
            get { _value }
            set {
                guard isMutable else { return }
                _value = newValue
            }
        }
        
        /// Indicates whether or not the form value is read-only.
        @objc public let isMutable: Bool
        
        /// Indicates whether or not the form value is required to successfully proceed through this remediation option.
        @objc public let isRequired: Bool
        
        /// Indicates whether or not the value supplied in this form value should be considered secret, and not presented to the user.
        @objc public let isSecret: Bool
        
        /// For composite form fields, this contains the nested array of form values to group together.
        @objc public let form: IDXClient.Remediation.Form?
        
        /// For form fields that have specific options the user can choose from (e.g. security question, passcode, etc), this indicates the different form options that should be displayed to the user.
        @objc public let options: [IDXClient.Remediation.Form.Field]?
        
        /// Indicates if this field is the selected option within a parent field's `options` array.
        @objc public internal(set) var isSelectedOption: Bool
        
        /// Allows a developer to set the selected option for a field that contains multiple `options`.
        ///
        /// This will update the `isSelectedOption` on all relevant fields.
        @objc public weak var selectedOption: IDXClient.Remediation.Form.Field? {
            didSet {
                guard let options = options else { return }
                for option in options {
                    option.isSelectedOption = (option === selectedOption)
                }
            }
        }
        
        /// The list of messages sent from the server.
        ///
        /// Messages reported from the server at the FormValue level should be considered relevant to the individual form field, and as a result should be displayed to the user alongside any UI elements associated with it.
        @objc public let messages: IDXClient.MessageCollection
        
        /// Relates this field to an authenticator, when a field is used to represent an authenticator. For example, when a field is used within a series of `options` to identify which authenticator to select.
        @objc public internal(set) weak var authenticator: IDXClient.Authenticator?

        /// Returns the nested `form` field with the given name.
        @objc public subscript(name: String) -> Field? {
            form?[name]
        }
        
        public subscript(dynamicMember name: String) -> Field? {
            form?[dynamicMember: name]
        }
        
        let isVisible: Bool
        let relatesTo: String?
        var _value: AnyObject?
        lazy var hasVisibleFields: Bool = {
            if isVisible {
                return true
            }
            
            if let form = form,
               !form.fields.lazy.filter({ $0.hasVisibleFields }).isEmpty
            {
                return true
            }
            
            if let options = options,
               !options.lazy.filter({ $0.hasVisibleFields }).isEmpty
            {
                return true
            }
            
            return false
        }()

        internal init(name: String? = nil,
                      label: String? = nil,
                      type: String? = nil,
                      value: AnyObject? = nil,
                      visible: Bool,
                      mutable: Bool,
                      required: Bool,
                      secret: Bool,
                      relatesTo: String? = nil,
                      form: IDXClient.Remediation.Form? = nil,
                      options: [IDXClient.Remediation.Form.Field]? = nil,
                      messages: IDXClient.MessageCollection = .init(messages: nil))
        {
            self.name = name
            self.label = label
            self.type = type
            self._value = value
            self.isVisible = visible
            self.isMutable = mutable
            self.isRequired = required
            self.isSecret = secret
            self.form = form
            self.relatesTo = relatesTo
            self.options = options
            self.messages = messages
            self.isSelectedOption = false
            
            super.init()
        }
    }
    
}
