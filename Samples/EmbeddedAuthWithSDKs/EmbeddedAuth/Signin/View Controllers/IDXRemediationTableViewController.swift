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

import UIKit
import OktaIdx
import AuthenticationServices

class IDXRemediationTableViewController: UITableViewController, IDXResponseController {
    var response: IDXClient.Response?
    var signin: Signin?

    private var webAuthSession: ASWebAuthenticationSession?
    private var formSections: [Signin.Section] = []
    private weak var poll: Pollable?

    private let pollActivityIndicator: UIActivityIndicatorView = {
        let result = UIActivityIndicatorView(style: .medium)
        result.hidesWhenStopped = true
        return result
    }()
    
    func rebuildForm() {
        if let response = response {
            formSections = response.remediationForm(delegate: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: pollActivityIndicator)
        
        rebuildForm()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        title = response?.app?.label
        navigationController?.setNavigationBarHidden(!shouldShowNavigationBar,
                                                     animated: animated)

        if let inputView = view.allInputFields().first {
            inputView.becomeFirstResponder()
        }
        
        if let poll = response?.authenticators.current as? IDXClient.Authenticator & Pollable,
           poll.canPoll
        {
            beginPolling(using: poll)
        }
    }
    
    var shouldShowNavigationBar: Bool {
        guard let response = response,
              let app = response.app
        else {
            return true
        }
        
        return !app.label.isEmpty && !response.remediations.isEmpty
    }
    
    @IBAction @objc func cancelAction() {
        signin?.failure(with: SigninError.genericError(message: "Cancelled"))
    }
    
    func proceed(to remediationOption: IDXClient.Remediation?, from sender: Any? = nil) {
        guard let signin = signin else {
            showError(SigninError.genericError(message: "Signin session deallocated"))
            return
        }
        
        //if let button = sender as? UIButton {
        //    button.isEnabled = false
        //}
        
        poll?.stopPolling()
        if let socialAuth = remediationOption as? IDXClient.Remediation.SocialAuth,
           let idx = signin.idx,
           let scheme = URL(string: idx.context.configuration.redirectUri)?.scheme
        {
            let session = ASWebAuthenticationSession(url: socialAuth.redirectUrl,
                                                     callbackURLScheme: scheme)
            { [weak self] (callbackURL, error) in
                guard error == nil,
                      let callbackURL = callbackURL
                else {
                    self?.showError(error ?? SigninError.genericError(message: "Could not authenticate"),
                                    recoverable: true)
                    return
                }
                
                let result = signin.idx?.redirectResult(for: callbackURL)
                
                switch result {
                case .authenticated:
                    idx.exchangeCode(redirect: callbackURL) { (token, error) in
                        if let error = error {
                            signin.failure(with: error)
                        } else if let token = token {
                            signin.success(with: token)
                        }
                    }
                    
                case .remediationRequired:
                    idx.resume { (response, error) in
                        if let error = error {
                            signin.failure(with: error)
                        } else if let response = response {
                            signin.proceed(to: response)
                        }
                    }
                case .invalidContext, .invalidRedirectUrl, .none:
                    return
                }
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
            
            self.webAuthSession = session
            
            return
        }

        remediationOption?.proceed { [weak self] (response, error) in
            guard let response = response else {
                if let error = error {
                    self?.showError(error, recoverable: true)
                }
                return
            }
            
            signin.proceed(to: response)
        }
    }
    
    func cancelAction(_ sender: Any?) {
        guard let signin = signin else {
            showError(SigninError.genericError(message: "Signin session deallocated"))
            return
        }

        if let button = sender as? UIButton {
            button.isEnabled = false
        }

        response?.cancel { [weak self] (response, error) in
            guard let response = response else {
                if let error = error {
                    self?.showError(error)
                    
                    signin.failure(with: error)
                }
                return
            }
            
            signin.proceed(to: response)
        }
    }
    
    func beginPolling(using poll: IDXClient.Authenticator & Pollable) {
        guard let signin = signin else {
            showError(SigninError.genericError(message: "Signin session deallocated"))
            return
        }

        if !pollActivityIndicator.isAnimating {
            pollActivityIndicator.startAnimating()
        }

        self.poll = poll
        poll.startPolling { [weak self] (response, error) in
            guard let response = response else {
                if let error = error {
                    self?.showError(error, recoverable: true)
                    self?.pollActivityIndicator.stopAnimating()
                    poll.stopPolling()
                }
                return
            }
            
            signin.proceed(to: response)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return formSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let formSection = formSections[section]
        return formSection.rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = formSections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.kind.reuseIdentifier, for: indexPath)

        row.configure(signin: signin, cell: cell, at: indexPath)

        return cell
    }
}

extension IDXRemediationTableViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window ?? UIWindow()
    }
}

extension IDXRemediationTableViewController: SigninRowDelegate {
    func value(for value: IDXClient.Remediation.Form.Field) -> Any? {
        return value.value
    }
    
    func formNeedsUpdate() {
        guard let response = response else { return }
        formSections = response.remediationForm(delegate: self)
        tableView.reloadData()
    }

    func enrollment(action: Signin.EnrollmentAction) {
        guard let signin = signin else { return }
        switch action {
        case .send:
            if let authenticator = response?.authenticators.current as? Sendable,
               authenticator.canSend
            {
                authenticator.send { (response, error) in
                    guard let response = response else {
                        signin.failure(with: error ?? SigninError.stepUnsupported)
                        return
                    }
                    
                    signin.proceed(to: response)
                }
            }
        case .resend:
            if let authenticator = response?.authenticators.current as? Resendable,
               authenticator.canResend
            {
                authenticator.resend { (response, error) in
                    guard let response = response else {
                        signin.failure(with: error ?? SigninError.stepUnsupported)
                        return
                    }
                    
                    signin.proceed(to: response)
                }
            }
        case .recover:
            if let authenticator = response?.authenticators.current as? Recoverable,
               authenticator.canRecover
            {
                authenticator.recover { (response, error) in
                    guard let response = response else {
                        signin.failure(with: error ?? SigninError.stepUnsupported)
                        return
                    }
                    
                    signin.proceed(to: response)
                }
            }
        }
    }
    
    func buttonSelected(remediationOption: IDXClient.Remediation, sender: Any?) {
        proceed(to: remediationOption, from: sender)
    }
}

extension Signin.Row.Kind {
    var reuseIdentifier: String {
        switch self {
        case .separator:                   return "Separator"
        case .title(remediationOption: _): return "Title"
        case .label(field: _):             return "Label"
        case .message(style: _):           return "Message"
        case .text(field: _):              return "Text"
        case .toggle(field: _):            return "Toggle"
        case .option(field: _,
                     option: _):           return "Option"
        case .select(field: _,
                     values: _):           return "Picker"
        case .button:                      return "Button"
        }
    }
}

extension Signin.Row {
    func configure(signin: Signin?, cell: UITableViewCell, at indexPath: IndexPath) {
        switch self.kind {
        case .separator:
            if cell is IDXSeparatorTableViewCell {
                // TODO:
            }

        case .title(remediationOption: let option):
            if let cell = cell as? IDXTitleTableViewCell {
                cell.titleLabel.text = option.title
            }

        case .label(field: let field):
            if let cell = cell as? IDXLabelTableViewCell {
                cell.fieldLabel.text = field.label
            }
            
        case .message(style: let style):
            if let cell = cell as? IDXMessageTableViewCell {
                cell.type = style
                cell.update = {
                    switch style {
                    case .enrollment(action: let action):
                        self.delegate?.enrollment(action: action)
                    default: break
                    }
                }
            }
            
        case .text(field: let field):
            if let cell = cell as? IDXTextTableViewCell,
               let fieldName = field.name
            {
                cell.fieldLabel.text = field.label
                cell.fieldLabel.accessibilityIdentifier = "\(fieldName).label"
                cell.textField.isSecureTextEntry = field.isSecret
                cell.textField.text = field.value as? String
                cell.textField.accessibilityIdentifier = "\(fieldName).field"
                cell.update = { value in
                    field.value = value
                }
            }
            
        case .toggle(field: let field):
            if let cell = cell as? IDXToggleTableViewCell,
               let fieldName = field.name
             {
                cell.fieldLabel.text = field.label
                cell.fieldLabel.accessibilityIdentifier = "\(fieldName).label"
                cell.switchView.isOn = field.value as? Bool ?? false
                cell.update = { (value) in
                    field.value = value
                }
            }
            
        case .option(field: let field, option: let option):
            if let cell = cell as? IDXOptionTableViewCell,
               let fieldName = field.name
            {
                if let authenticator = option.authenticator as? IDXClient.Authenticator & HasProfile,
                   let profile = authenticator.profile
                {
                    cell.detailLabel.text = profile.values.first
                } else {
                    cell.detailLabel.text = nil
                }

                cell.fieldLabel.text = option.label
                cell.fieldLabel.accessibilityIdentifier = "\(fieldName).label"
                cell.state = option.isSelectedOption ? .checked : .unchecked
                cell.update = {
                    field.selectedOption = option
                    delegate?.formNeedsUpdate()
                }
            }
            
        case .button(remediationOption: let option):
            if let cell = cell as? IDXButtonTableViewCell {
                cell.style = .remediation(type: option.type)
                cell.buttonView.setTitle(signin?.buttonTitle(for: option), for: .normal)
                cell.update = { (sender, _) in
                    delegate?.buttonSelected(remediationOption: option, sender: sender)
                }
            }
            
        case .select(field: let field, values: let values):
            if let cell = cell as? IDXPickerTableViewCell,
               let fieldName = field.name
            {
                let currentValue = field.selectedOption?.value as? String
                
                cell.fieldLabel.text = field.label
                cell.fieldLabel.accessibilityIdentifier = "\(fieldName).label"
                cell.options = values.compactMap { field in
                    guard let value = field.value as? String,
                          let label = field.label else { return nil }
                    return (value, label)
                }
                cell.selectedValue = currentValue
                cell.update = { value in
                    field.selectedOption = values.first { $0.value as? String == value }
                }
            }
            
        }
    }
}
