/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation
import OktaIdx

protocol SigninRowDelegate {
    func formNeedsUpdate()
    func enrollment(action: Signin.EnrollmentAction)
    func buttonSelected(remediationOption: IDXClient.Remediation, sender: Any?)
}

extension Signin {
    /// Represents a visual row in the remediation form's signin process.
    struct Row {
        /// The kind of element to display in this row
        let kind: Kind
        
        /// The parent form value, if present, that this row's value should be submitted under.
        let parent: IDXClient.Remediation.Form.Field?
        
        /// Delegate to notfiy about user interactions and value changes
        weak private(set) var delegate: (AnyObject & SigninRowDelegate)?
        
        /// Row element kinds.
        enum Kind {
            case separator
            case title(remediationOption: IDXClient.Remediation)
            case label(field: IDXClient.Remediation.Form.Field)
            case message(style: IDXMessageTableViewCell.Style)
            case text(field: IDXClient.Remediation.Form.Field)
            case toggle(field: IDXClient.Remediation.Form.Field)
            case option(field: IDXClient.Remediation.Form.Field, option: IDXClient.Remediation.Form.Field)
            case select(field: IDXClient.Remediation.Form.Field, values: [IDXClient.Remediation.Form.Field])
            case button(remediationOption: IDXClient.Remediation)
        }
    }
    
    /// Represents a section of rows for the remediation form's signin process
    struct Section {
        let remediationOption: IDXClient.Remediation?
        
        /// Array of rows to show in this section.
        let rows: [Row]
    }
    
    enum EnrollmentAction {
        case send, resend, recover
    }
}

extension IDXClient.Remediation.Form.Field {
    typealias Section = Signin.Section
    typealias Row = Signin.Row
    typealias Form = IDXClient.Remediation.Form
    
    /// Returns an array of row elements to represent this form value's input.
    /// - Parameters:
    ///   - parent: Optional parent for this form value.
    ///   - delegate: The delegate to receive updates from this form row.
    /// - Returns: Array of row elements.
    func remediationRow(parent: Form.Field? = nil, delegate: AnyObject & SigninRowDelegate) -> [Row] {
        if !isMutable {
            if label != nil {
                // Fields that are not "visible" don't mean they shouldn't be displayed, just that they
                return [Row(kind: .label(field: self),
                            parent: parent,
                            delegate: delegate)]
            } else {
                return []
            }
        }
        
        var rows: [Row] = []
        
        switch type {
        case "boolean":
            rows.append(Row(kind: .toggle(field: self),
                            parent: parent,
                            delegate: delegate))
        case "object":
            if let options = options {
                options.forEach { option in
                    rows.append(Row(kind: .option(field: self, option: option),
                                    parent: parent,
                                    delegate: delegate))
                    if option.isSelectedOption,
                       let form = option.form
                    {
                        rows.append(contentsOf: form.flatMap { nested in
                            nested.remediationRow(delegate: delegate)
                        })
                    }
                }
            } else if let form = form {
                rows.append(contentsOf: form.flatMap { nested in
                    nested.remediationRow(parent: self, delegate: delegate)
                })
            }
            
        default:
            if let options = options {
                rows.append(Row(kind: .select(field: self, values: options),
                                parent: parent,
                                delegate: delegate))
            } else if let form = form {
                rows.append(contentsOf: form.flatMap { formValue in
                    formValue.remediationRow(parent: self, delegate: delegate)
                })
            } else {
                rows.append(Row(kind: .text(field: self),
                                parent: parent,
                                delegate: delegate))
            }
        }
        
        self.messages.forEach { message in
            rows.append(Row(kind: .message(style: .message(message: message)),
                            parent: parent,
                            delegate: delegate))
        }
        
        return rows
    }
}

extension IDXClient.Remediation {
    class func title(for type: IDXClient.Remediation.RemediationType) -> String {
        switch type {
        case .selectEnrollProfile: fallthrough
        case .enrollProfile:
            return "Sign Up"
            
        case .selectIdentify: fallthrough
        case .identify:
            return "Sign In"
        
        case .challengeAuthenticator:
            return "Password"
            
        case .selectAuthenticatorAuthenticate:
            return "Choose Method"
            
        case .skip:
            return "Skip"
            
        case .cancel:
            return "Restart"
            
        default:
            return "Next"
        }
    }
    
    var title: String {
        return IDXClient.Remediation.title(for: type)
    }
}

extension IDXClient.Response {
    typealias Section = Signin.Section
    typealias Row = Signin.Row
    typealias Form = IDXClient.Remediation.Form
    
    /// Converts the response to a series of remediation forms to display in the UI
    /// - Parameter delegate: A delegate object to receive updates as the form is changed.
    /// - Returns: Array of sections to be shown in the table view.
    func remediationForm(delegate: AnyObject & SigninRowDelegate) -> [Section] {
        var result: [Section] = []
        
        if !messages.isEmpty {
            result.append(Section(remediationOption: nil,
                                  rows: messages.map { message in
                                    Row(kind: .message(style: .message(message: message)),
                                        parent: nil,
                                        delegate: delegate)
                                  }))
        }
        
        result.append(contentsOf: remediations.map { option in
            self.remediationForm(remediationOption: option, in: self, delegate: delegate)
        })

        return result
    }

    /// Converts a remediation option into a set of objects representing the form, so it can be rendered in the table view.
    /// - Parameters:
    ///   - response: Response object that is the parent for this remediation option
    ///   - delegate: A delegate object to receive updates as the form is changed.
    /// - Returns: Array of sections to be shown in the table view.
    func remediationForm(remediationOption: IDXClient.Remediation, in response: IDXClient.Response, delegate: AnyObject & SigninRowDelegate) -> Section {
        var rows: [Row] = []
        
        // Based on which remediation option we're in, show either a title or separator
        switch response.remediations.firstIndex(of: remediationOption) {
        case 0:
            rows.append(Row(kind: .title(remediationOption: remediationOption), parent: nil, delegate: nil))
        case 1:
            rows.append(Row(kind: .separator, parent: nil, delegate: nil))
        default: break
        }
        
        if !remediationOption.messages.isEmpty {
            rows.append(contentsOf: messages.map { message in
                Row(kind: .message(style: .message(message: message)),
                    parent: nil,
                    delegate: delegate)
            })
        }
        
        rows.append(contentsOf: remediationOption.form.flatMap { nested in
            nested.remediationRow(delegate: delegate)
        })
        rows.append(Row(kind: .button(remediationOption: remediationOption),
                        parent: nil,
                        delegate: delegate))

        for (_,authenticator) in remediationOption.authenticators {
            if let sendable = authenticator as? Sendable,
               sendable.canSend
            {
                rows.append(Row(kind: .message(style: .enrollment(action: .send)),
                                parent: nil,
                                delegate: delegate))
            }
            
            if let resendable = authenticator as? Resendable,
               resendable.canResend
            {
                rows.append(Row(kind: .message(style: .enrollment(action: .resend)),
                                parent: nil,
                                delegate: delegate))
            }
            
            if let recoverable = authenticator as? Recoverable,
               recoverable.canRecover
            {
                rows.append(Row(kind: .message(style: .enrollment(action: .recover)),
                                parent: nil,
                                delegate: delegate))
            }
        }

        return Section(remediationOption: remediationOption, rows: rows)
    }
}
