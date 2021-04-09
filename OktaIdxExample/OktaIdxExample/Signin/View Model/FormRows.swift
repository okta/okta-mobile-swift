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
    func row(row: Signin.Row, changedValue: (IDXClient.Remediation.FormValue,Any))
    func value(for value: IDXClient.Remediation.FormValue) -> Any?
    func enrollment(action: Signin.EnrollmentAction)
    func buttonSelected(remediationOption: IDXClient.Remediation.Option?, sender: Any?)
}

extension Signin {
    /// Represents a visual row in the remediation form's signin process.
    struct Row {
        /// The kind of element to display in this row
        let kind: Kind
        
        /// The parent form value, if present, that this row's value should be submitted under.
        let parent: IDXClient.Remediation.FormValue?
        
        /// Delegate to notfiy about user interactions and value changes
        weak private(set) var delegate: (AnyObject & SigninRowDelegate)?
        
        /// Row element kinds.
        enum Kind {
            case separator
            case title(remediationOption: IDXClient.Remediation.Option)
            case label(field: IDXClient.Remediation.FormValue)
            case message(style: IDXMessageTableViewCell.Style)
            case text(field: IDXClient.Remediation.FormValue)
            case toggle(field: IDXClient.Remediation.FormValue)
            case option(field: IDXClient.Remediation.FormValue, option: IDXClient.Remediation.FormValue)
            case select(field: IDXClient.Remediation.FormValue, values: [IDXClient.Remediation.FormValue])
            case button(remediationOption: IDXClient.Remediation.Option?)
        }
    }
    
    /// Represents a section of rows for the remediation form's signin process
    struct Section {
        let remediationOption: IDXClient.Remediation.Option?
        
        /// Array of rows to show in this section.
        let rows: [Row]
    }
    
    enum EnrollmentAction {
        case send, resend, recover
    }
}

extension IDXClient.Remediation.FormValue {
    typealias Section = Signin.Section
    typealias Row = Signin.Row
    typealias FormValue = IDXClient.Remediation.FormValue
    
    /// Returns an array of row elements to represent this form value's input.
    /// - Parameters:
    ///   - parent: Optional parent for this form value.
    ///   - delegate: The delegate to receive updates from this form row.
    /// - Returns: Array of row elements.
    func remediationRow(parent: FormValue? = nil, delegate: AnyObject & SigninRowDelegate) -> [Row] {
        if !visible && !mutable {
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

                    if let optionForm = option.form,
                       let chosenValue = delegate.value(for: self) as? FormValue
                    {
                        if chosenValue == option {
                            optionForm.forEach { childValue in
                                rows.append(contentsOf: childValue.remediationRow(parent: self, delegate: delegate))
                            }
                        }
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
            } else if visible {
                rows.append(Row(kind: .text(field: self),
                                parent: parent,
                                delegate: delegate))
            } else if let form = form {
                rows.append(contentsOf: form.flatMap { formValue in
                    formValue.remediationRow(parent: self, delegate: delegate)
                })
            }
        }
        
        self.messages?.forEach { message in
            rows.append(Row(kind: .message(style: .message(message: message)),
                            parent: parent,
                            delegate: delegate))
        }
        
        return rows
    }

    var hasVisibleFields: Bool {
        get {
            if visible {
                return true
            }
            
            return (options?.filter { $0.hasVisibleFields }.count ?? 0 > 0)
        }
    }
}

extension IDXClient.Remediation.Option {
    class func title(for type: IDXClient.Remediation.RemediationType?) -> String {
        guard let type = type else { return "Restart" }
        switch type {
        case .selectEnrollProfile: fallthrough
        case .enrollProfile:
            return "Create profile"
            
        case .selectIdentify: fallthrough
        case .identify:
            return "Sign in"
        
        case .challengeAuthenticator:
            return "Password"
            
        case .selectAuthenticatorAuthenticate:
            return "Choose method"
            
        case .skip:
            return "Skip"
            
        default:
            return "Next"
        }
    }
    
    var title: String {
        return IDXClient.Remediation.Option.title(for: type)
    }
}

extension IDXClient.Response {
    typealias Section = Signin.Section
    typealias Row = Signin.Row
    typealias FormValue = IDXClient.Remediation.FormValue
    
    /// Converts the response to a series of remediation forms to display in the UI
    /// - Parameter delegate: A delegate object to receive updates as the form is changed.
    /// - Returns: Array of sections to be shown in the table view.
    func remediationForm(delegate: AnyObject & SigninRowDelegate) -> [Section] {
        var result: [Section] = []
        
        if let messages = messages {
            result.append(Section(remediationOption: nil,
                                  rows: messages.map { message in
                                    Row(kind: .message(style: .message(message: message)),
                                        parent: nil,
                                        delegate: delegate)
                                  }))
        }
        
        if let remediationOptions = remediation?.remediationOptions {
            result.append(contentsOf: remediationOptions.map { option in
                self.remediationForm(remediationOption: option, in: self, delegate: delegate)
            })
        }
        
        if canCancel {
            result.append(Section(remediationOption: nil,
                                  rows: [
                                    Row(kind: .button(remediationOption: nil),
                                        parent: nil,
                                        delegate: delegate)]))
        }

        return result
    }

    /// Converts a remediation option into a set of objects representing the form, so it can be rendered in the table view.
    /// - Parameters:
    ///   - response: Response object that is the parent for this remediation option
    ///   - delegate: A delegate object to receive updates as the form is changed.
    /// - Returns: Array of sections to be shown in the table view.
    func remediationForm(remediationOption: IDXClient.Remediation.Option, in response: IDXClient.Response, delegate: AnyObject & SigninRowDelegate) -> Section {
        var rows: [Row] = []
        
        if response.remediation?.remediationOptions.first == remediationOption {
            rows.append(Row(kind: .title(remediationOption: remediationOption), parent: nil, delegate: nil))
        } else {
            rows.append(Row(kind: .separator, parent: nil, delegate: nil))
        }
        
        if let messages = messages {
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

        if let enrollment = currentAuthenticatorEnrollment {
            if enrollment.send != nil {
                rows.append(Row(kind: .message(style: .enrollment(action: .send)),
                                parent: nil,
                                delegate: delegate))
            }

            if enrollment.resend != nil {
                rows.append(Row(kind: .message(style: .enrollment(action: .resend)),
                                parent: nil,
                                delegate: delegate))
            }

            if enrollment.recover != nil {
                rows.append(Row(kind: .message(style: .enrollment(action: .recover)),
                                parent: nil,
                                delegate: delegate))
            }
        }

        return Section(remediationOption: remediationOption, rows: rows)
    }
}
