//
//  IDXStartViewController.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-08.
//

import UIKit
import OktaIdx

protocol IDXSigninController {
    var signin: Signin? { get set }
    func showError(_ error: Error)
}
extension IDXSigninController where Self: UIViewController {
    func showError(_ error: Error) {
        let parentController = navigationController?.presentingViewController
        dismiss(animated: true) {
            let alert = UIAlertController(title: "Login error",
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            parentController?.present(alert, animated: true) {
                self.signin?.failure(with: error)
            }
        }
    }
}

protocol IDXResponseController: IDXSigninController {
    var response: IDXClient.Response? { get set }
}

protocol IDXRemediationController: IDXResponseController {
    var remediationOption: IDXClient.Remediation.Option? { get set }
}
