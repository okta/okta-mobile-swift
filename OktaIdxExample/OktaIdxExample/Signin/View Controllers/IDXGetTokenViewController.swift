//
//  IDXGetTokenViewController.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-08.
//

import UIKit
import OktaIdx

/// Sign in view controller used when login is successful, and encapsulates the `IDXClient.Response.getToken()` method.
class IDXGetTokenViewController: UIViewController, IDXResponseController {
    var signin: Signin?
    var response: IDXClient.Response?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)

        guard let signin = signin,
              let response = response else
        {
            showError(SigninError.genericError(message: "Signin session or response is missing"))
            return
        }
        
        response.exchangeCode { [weak self] (token, error) in
            guard let token = token else {
                if let error = error {
                    self?.showError(error)
                    
                    signin.failure(with: error)
                }
                return
            }
            
            signin.success(with: token)
        }
    }
}
