/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import UIKit

protocol SigninRowDelegate {
    func formNeedsUpdate()
    func enrollment(action: Signin.EnrollmentAction)
    func buttonSelected(remediationOption: Remediation, sender: Any?)
}

extension Signin {
    /// Represents a visual row in the remediation form's signin process.
    struct Row: Hashable {
        static func == (lhs: Signin.Row, rhs: Signin.Row) -> Bool {
            return lhs.kind == rhs.kind &&
                lhs.parent == rhs.parent
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(kind)
            hasher.combine(parent)
        }
        
        /// The kind of element to display in this row
        let kind: Kind
        
        /// The parent form value, if present, that this row's value should be submitted under.
        let parent: Remediation.Form.Field?
        
        /// Delegate to notfiy about user interactions and value changes
        weak private(set) var delegate: (AnyObject & SigninRowDelegate)?
        
        /// Row element kinds.
        enum Kind: Hashable {
            static func == (lhs: Signin.Row.Kind, rhs: Signin.Row.Kind) -> Bool {
                switch (lhs, rhs) {
                case (.separator, .separator):
                    return true
                case (.image(let lhsValue), .image(let rhsValue)):
                    return lhsValue == rhsValue
                case (.title(remediationOption: let lhsValue), .title(remediationOption: let rhsValue)):
                    return lhsValue == rhsValue
                case (.label(field: let lhsValue), .label(field: let rhsValue)):
                    return lhsValue == rhsValue
                case (.message(style: let lhsValue), .message(style: let rhsValue)):
                    return lhsValue == rhsValue
                case (.numberChallenge(answer: let lhsValue), .numberChallenge(answer: let rhsValue)):
                    return lhsValue == rhsValue
                case (.text(field: let lhsValue), .text(field: let rhsValue)):
                    return lhsValue == rhsValue
                case (.toggle(field: let lhsValue), .toggle(field: let rhsValue)):
                    return lhsValue == rhsValue
                case (.option(field: let lhsValue, option: let lhsOption), .option(field: let rhsValue, option: let rhsOption)):
                    return lhsValue == rhsValue && lhsOption == rhsOption
                case (.select(field: let lhsValue, values: let lhsOption), .select(field: let rhsValue, values: let rhsOption)):
                    return lhsValue == rhsValue && lhsOption == rhsOption
                case (.button(remediationOption: let lhsValue), .button(remediationOption: let rhsValue)):
                    return lhsValue == rhsValue
                default:
                    return false
                }
            }
            
            case separator
            case title(remediationOption: Remediation)
            case label(field: Remediation.Form.Field)
            case image(_ image: UIImage)
            case message(style: IDXMessageTableViewCell.Style)
            case numberChallenge(answer: String)
            case text(field: Remediation.Form.Field)
            case toggle(field: Remediation.Form.Field)
            case option(field: Remediation.Form.Field, option: Remediation.Form.Field)
            case select(field: Remediation.Form.Field, values: [Remediation.Form.Field])
            case button(remediationOption: Remediation)
        }
    }
    
    /// Represents a section of rows for the remediation form's signin process
    struct Section: Hashable {
        let remediationOption: Remediation?
    }
    
    enum EnrollmentAction {
        case send, resend, recover
    }
}

extension Remediation.Form.Field {
    typealias Section = Signin.Section
    typealias Row = Signin.Row
    typealias Form = Remediation.Form
    
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

extension Remediation {
    class func title(for type: Remediation.RemediationType) -> String {
        switch type {
        case .selectEnrollProfile, .enrollProfile:
            return "Sign Up"
            
        case .selectIdentify, .identify:
            return "Sign In"
        
        case .challengeAuthenticator:
            return "Password"
            
        case .selectAuthenticatorAuthenticate:
            return "Choose Method"
            
        case .skip:
            return "Skip"
            
        case .cancel:
            return "Restart"
            
        case .enrollPoll, .challengePoll:
            return "Verify"
            
        case .unlockAccount, .selectAuthenticatorUnlockAccount:
            return "Unlock Account"
            
        default:
            return "Next"
        }
    }
    
    var title: String {
        Remediation.title(for: type)
    }
}

extension Response {
    typealias Section = Signin.Section
    typealias Row = Signin.Row
    typealias Form = Remediation.Form
    
    /// Converts the response to a series of remediation forms to display in the UI
    /// - Parameter delegate: A delegate object to receive updates as the form is changed.
    /// - Returns: Array of sections to be shown in the table view.
    func buildFormSnapshot(_ snapshot: inout NSDiffableDataSourceSnapshot<Signin.Section, Signin.Row>,
                           delegate: AnyObject & SigninRowDelegate)
    {
        if !messages.isEmpty {
            let section = Section(remediationOption: nil)
            let rows = messages.map { message in
                Row(kind: .message(style: .message(message: message)),
                    parent: nil,
                    delegate: delegate)
              }
            snapshot.appendSections([ section ])
            snapshot.appendItems(rows, toSection: section)
        }
        
        remediations.forEach { option in
            self.buildFormSnapshot(&snapshot, remediationOption: option, in: self, delegate: delegate)
        }
    }

    /// Converts a remediation option into a set of objects representing the form, so it can be rendered in the table view.
    /// - Parameters:
    ///   - response: Response object that is the parent for this remediation option
    ///   - delegate: A delegate object to receive updates as the form is changed.
    /// - Returns: Array of sections to be shown in the table view.
    func buildFormSnapshot(_ snapshot: inout NSDiffableDataSourceSnapshot<Signin.Section, Signin.Row>,
                           remediationOption: Remediation,
                           in response: Response,
                           delegate: AnyObject & SigninRowDelegate)
    {
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
        
        if let otp = remediationOption.authenticators.current?.otp,
           let image = otp.image
        {
            rows.append(Row(kind: .image(image), parent: nil, delegate: nil))
        }
        
        if let numberChallenge = remediationOption.authenticators.current?.numberChallenge {
            rows.append(Row(kind: .numberChallenge(answer: numberChallenge.correctAnswer),
                            parent: nil,
                            delegate: nil))
        }
        
        rows.append(contentsOf: remediationOption.form.flatMap { nested in
            nested.remediationRow(delegate: delegate)
        })
        
        // Don't show a remediation option for strictly-pollable remediations
        if !(remediationOption.pollable != nil &&
             remediationOption.form.isEmpty)
        {
            rows.append(Row(kind: .button(remediationOption: remediationOption),
                            parent: nil,
                            delegate: delegate))
        }
        
        for authenticator in remediationOption.authenticators {
            if authenticator.sendable != nil {
                rows.append(Row(kind: .message(style: .enrollment(action: .send)),
                                parent: nil,
                                delegate: delegate))
            }
            
            if authenticator.resendable != nil {
                rows.append(Row(kind: .message(style: .enrollment(action: .resend)),
                                parent: nil,
                                delegate: delegate))
            }
            
            if authenticator.recoverable != nil {
                rows.append(Row(kind: .message(style: .enrollment(action: .recover)),
                                parent: nil,
                                delegate: delegate))
            }
        }
        
        let section = Section(remediationOption: remediationOption)
        snapshot.appendSections([ section ])
        snapshot.appendItems(rows, toSection: section)
    }
}
