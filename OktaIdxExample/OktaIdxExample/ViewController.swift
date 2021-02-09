//
//  ViewController.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-04.
//

import UIKit
import OktaIdx

extension ClientConfiguration {
    var idxConfiguration: IDXClient.Configuration {
        return IDXClient.Configuration(issuer: issuer,
                                       clientId: clientId,
                                       clientSecret: nil,
                                       scopes: ["openid", "profile", "offline_access"],
                                       redirectUri: redirectUri)
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var issuerField: UITextField!
    @IBOutlet weak var clientIdField: UITextField!
    @IBOutlet weak var redirectField: UITextField!
    private var signin: Signin?
    var configuration: ClientConfiguration? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configuration = ClientConfiguration.launchConfiguration ?? ClientConfiguration.userDefaults
        issuerField.text = configuration?.issuer
        clientIdField.text = configuration?.clientId
        redirectField.text = configuration?.redirectUri
        
        issuerField.accessibilityIdentifier = "issuerField"
        clientIdField.accessibilityIdentifier = "clientIdField"
        redirectField.accessibilityIdentifier = "redirectField"
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundTapped)))
    }
    
    @objc func backgroundTapped() {
        view.allInputFields()
            .filter { $0.isFirstResponder }
            .forEach { $0.resignFirstResponder() }
    }
    
    func loginComplete(with token: IDXClient.Token) {
        print("Authenticated with \(token)")
    }

    @IBAction func logIn(_ sender: Any) {
        guard let issuerUrl = issuerField.text,
              let clientId = clientIdField.text,
              let redirectUri = redirectField.text else
        {
            let alert = UIAlertController(title: "Invalid configuration",
                                          message: nil,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }

        configuration = ClientConfiguration(clientId: clientId,
                                            issuer: issuerUrl,
                                            redirectUri: redirectUri,
                                            shouldSave: true)
        configuration?.save()
        
        guard let config = configuration?.idxConfiguration else {
            return
        }
        
        signin = Signin(using: config)
        signin?.signin(from: self) { [weak self] (token, error) in
            if let error = error {
                print("Could not sign in: \(error)")
            } else {
                guard let controller = self?.storyboard?.instantiateViewController(identifier: "TokenResult") as? TokenResultViewController else { return }
                controller.token = token
                self?.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case issuerField:
            clientIdField.becomeFirstResponder()
        case clientIdField:
            redirectField.becomeFirstResponder()
        case redirectField:
            redirectField.resignFirstResponder()
            logIn(redirectField as Any)
            
        default: break
        }
        return false
    }
}
