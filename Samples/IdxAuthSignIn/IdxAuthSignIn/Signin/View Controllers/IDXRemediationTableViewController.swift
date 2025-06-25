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

import UIKit
import OktaIdxAuth
import AuthenticationServices

class IDXRemediationTableViewController: UITableViewController, IDXResponseController {
    var response: Response?
    var signin: Signin?

    private var webAuthSession: ASWebAuthenticationSession?
    private var authController: ASAuthorizationController?
    private var authRemediationOption: Remediation?
    private weak var poll: PollCapability?
    
    private var dataSource: UITableViewDiffableDataSource<Signin.Section, Signin.Row>!

    private let pollActivityIndicator: UIActivityIndicatorView = {
        let result = UIActivityIndicatorView(style: .medium)
        result.hidesWhenStopped = true
        return result
    }()
    
    func rebuildForm(animated: Bool = false) {
        if let response = response {
            var snapshot = NSDiffableDataSourceSnapshot<Signin.Section, Signin.Row>()
            response.buildFormSnapshot(&snapshot, delegate: self)
            dataSource.apply(snapshot, animatingDifferences: animated, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: pollActivityIndicator)
        tableView.dataSource = dataSource
        
        dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] (tableView, indexPath, row) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: row.kind.reuseIdentifier, for: indexPath)

            row.configure(signin: self?.signin, cell: cell, at: indexPath)

            return cell
        })
        
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
        
        if let poll = response?.authenticators.current?.pollable {
            beginPolling(using: poll)
        }
        
        else if let poll = response?.remediations.compactMap({ $0.pollable }).first {
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
    
    func authorize(magicLink code: String) {
        guard let remediation = response?.remediations[.challengeAuthenticator],
              remediation.authenticators.current?.type == .email,
              let passcodeField = remediation["credentials.passcode"]
        else {
            return
        }
        
        passcodeField.value = code
        proceed(to: remediation)
    }

    func proceed(to remediationOption: Remediation?, from sender: Any? = nil) {
        guard let signin = signin else {
            showError(SigninError.genericError(message: "Signin session deallocated"))
            return
        }
        
        //if let button = sender as? UIButton {
        //    button.isEnabled = false
        //}
        
        poll?.cancel()
        if let socialAuth = remediationOption?.socialIdp,
           let scheme = signin.flow.client.configuration.redirectUri?.scheme
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

                Task {
                    do {
                        switch try await signin.flow.resume(with: callbackURL) {
                        case .success(let token):
                            signin.success(with: token)
                        case .interactionRequired(let response):
                            signin.proceed(to: response)
                        }
                    } catch {
                        signin.failure(with: error)
                    }
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            session.start()
            
            self.webAuthSession = session
            
            return
        }

        else if let webAuthnRegistration = remediationOption?.webAuthnRegistration {
            let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: webAuthnRegistration.relyingPartyIdentifier)
            let platformKeyRequest = platformProvider.createCredentialRegistrationRequest(
                challenge: webAuthnRegistration.challenge,
                name: webAuthnRegistration.name,
                userID: webAuthnRegistration.userId)

            let authController = ASAuthorizationController(authorizationRequests: [platformKeyRequest])
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()

            self.authController = authController
            self.authRemediationOption = remediationOption
            return
        }

        else if let webAuthnAuthentication = remediationOption?.webAuthnAuthentication {
            let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: webAuthnAuthentication.relyingPartyIdentifier)
            let assertionRequest = platformProvider.createCredentialAssertionRequest(challenge: webAuthnAuthentication.challenge)
            let authController = ASAuthorizationController(authorizationRequests: [assertionRequest])
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()

            self.authController = authController
            self.authRemediationOption = remediationOption
            return
        }

        guard let remediationOption else { return }
        Task { @MainActor in
            do {
                signin.proceed(to: try await remediationOption.proceed())
            } catch {
                showError(error, recoverable: true)
            }
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

        guard let response else { return }
        Task { @MainActor in
            do {
                signin.proceed(to: try await response.restart())
            } catch {
                showError(error)
            }
        }
    }
    
    func beginPolling(using poll: PollCapability) {
        guard let signin = signin else {
            showError(SigninError.genericError(message: "Signin session deallocated"))
            return
        }

        if !pollActivityIndicator.isAnimating {
            pollActivityIndicator.startAnimating()
        }

        self.poll = poll
        Task { @MainActor in
            do {
                signin.proceed(to: try await poll.proceed())
            } catch {
                poll.cancel()
                showError(error, recoverable: true)
                pollActivityIndicator.stopAnimating()
            }
        }
    }
}

extension IDXRemediationTableViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window ?? UIWindow()
    }
}

extension IDXRemediationTableViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization)
    {
        guard let signin = signin else { return }

        switch authorization.credential {
        case let credential as ASAuthorizationPlatformPublicKeyCredentialRegistration:
            if let attestation = credential.rawAttestationObject,
               let capability = authRemediationOption?.webAuthnRegistration
            {
                Task { @MainActor in
                    do {
                        signin.proceed(to: try await capability.register(attestation: attestation,
                                                                         clientJSON: credential.rawClientDataJSON))
                    } catch {
                        signin.failure(with: error)
                    }
                }
            }
            break
        case let credential as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            if let authenticatorData = credential.rawAuthenticatorData,
               let signatureData = credential.signature,
               let capability = authRemediationOption?.webAuthnAuthentication
            {
                Task { @MainActor in
                    do {
                        signin.proceed(to: try await capability.challenge(authenticatorData: authenticatorData,
                                                                          clientData: credential.rawClientDataJSON,
                                                                          signatureData: signatureData))
                    } catch {
                        signin.failure(with: error)
                    }
                }
            }
            break
        default:
            // Handle other authentication cases, such as Sign in with Apple.
            break
        }

        authController = nil
        authRemediationOption = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        authController = nil
        authRemediationOption = nil

        Task { @MainActor in
            showError(error)
        }
    }
}

extension IDXRemediationTableViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window ?? UIWindow()
    }
}

extension IDXRemediationTableViewController: SigninRowDelegate {
    func value(for value: Remediation.Form.Field) -> Any? {
        return value.value
    }
    
    func formNeedsUpdate() {
        rebuildForm(animated: true)
    }

    func enrollment(action: Signin.EnrollmentAction) {
        guard let signin = signin else { return }
        switch action {
        case .send:
            if let sendable = response?.authenticators.current?.sendable {
                Task { @MainActor in
                    do {
                        signin.proceed(to: try await sendable.send())
                    } catch {
                        signin.failure(with: error)
                    }
                }
            }
        case .resend:
            if let resendable = response?.authenticators.current?.resendable {
                Task { @MainActor in
                    do {
                        signin.proceed(to: try await resendable.resend())
                    } catch {
                        signin.failure(with: error)
                    }
                }
            }
        case .recover:
            if let recoverable = response?.authenticators.current?.recoverable {
                Task { @MainActor in
                    do {
                        signin.proceed(to: try await recoverable.recover())
                    } catch {
                        signin.failure(with: error)
                    }
                }
            }
        }
    }
    
    func buttonSelected(remediationOption: Remediation, sender: Any?) {
        proceed(to: remediationOption, from: sender)
    }
}

extension Signin.Row.Kind {
    var reuseIdentifier: String {
        switch self {
        case .separator:                   return "Separator"
        case .title(remediationOption: _): return "Title"
        case .image(_):                    return "Image"
        case .label(field: _):             return "Label"
        case .message(style: _):           return "Message"
        case .numberChallenge(answer: _):  return "Title"
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

        case .image(let image):
            if let cell = cell as? IDXImageTableViewCell {
                cell.imageContentView.image = image
            }
            
        case .label(field: let field):
            if let cell = cell as? IDXLabelTableViewCell {
                cell.fieldLabel.text = field.label
            }
            
        case .numberChallenge(answer: let answer):
            if let cell = cell as? IDXTitleTableViewCell {
                cell.titleLabel.text = "Correct answer: \(answer)"
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
                if let profile = option.authenticator?.profile?.values.values.first {
                    cell.detailLabel.text = profile
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
                cell.style = .remediation(type: option.type,
                                          authenticatorType: option.authenticators.first?.type)
                cell.buttonView.setTitle(signin?.buttonTitle(for: option),
                                         for: .normal)
                cell.update = { (sender, _) in
                    delegate?.buttonSelected(remediationOption: option,
                                             sender: sender)
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
