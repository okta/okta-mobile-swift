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

extension Remediation.Form {
    /// Describes an individual field within a form, used to collect and submit information from the user to proceed through the authentication workflow.
    ///
    /// Nested form values can be accessed through keyed subscripting, for example:
    ///
    /// ```swift
    /// remediation.form["identifier"]
    /// ```
    ///
    /// > Note: This keyed subscripting is made available through the parent ``Remediation`` object. So the above example is equally expressed as the following:
    /// > ```swift
    /// > remediation["identifier"]
    /// > ```
    public final class Field: NSObject {
        /// The programmatic name for this form value.
        public let name: String?
        
        /// The user-readable label describing this form value.
        public let label: String?
        
        /// The type of value expected from the client.
        public let type: String?
        
        /// The value to send, if a default is provided from the Identity Engine.
        public var value: APIRequestArgument? {
            get { _value as? APIRequestArgument }
            set {
                guard isMutable else { return }
                _value = newValue as AnyObject
            }
        }
        
        /// Indicates whether or not the form value is read-only.
        public let isMutable: Bool
        
        /// Indicates whether or not the form value is required to successfully proceed through this remediation option.
        public let isRequired: Bool
        
        /// Indicates whether or not the value supplied in this form value should be considered secret, and not presented to the user.
        public let isSecret: Bool
        
        /// For composite form fields, this contains the nested array of form values to group together.
        public let form: Remediation.Form?
        
        /// For form fields that have specific options the user can choose from (e.g. security question, passcode, etc), this indicates the different form options that should be displayed to the user.
        public let options: [Remediation.Form.Field]?
        
        /// Indicates if this field is the selected option within a parent field's `options` array.
        public internal(set) var isSelectedOption: Bool
        
        /// Allows a developer to set the selected option for a field that contains multiple `options`.
        ///
        /// This will update the ``isSelectedOption`` on all relevant fields.
        public weak var selectedOption: Remediation.Form.Field? {
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
        public let messages: Response.Message.Collection
        
        /// Relates this field to an authenticator, when a field is used to represent an authenticator. For example, when a field is used within a series of ``options`` to identify which authenticator to select.
        public internal(set) weak var authenticator: Authenticator?

        /// Returns the nested `form` field with the given name.
        public subscript(name: String) -> Field? {
            form?[name]
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
                      form: Remediation.Form? = nil,
                      options: [Remediation.Form.Field]? = nil,
                      messages: Response.Message.Collection = .init(messages: nil))
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
