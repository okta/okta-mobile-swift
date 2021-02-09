//
//  IDXStartViewController.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-08.
//

import UIKit
import OktaIdx

/// Sign in controller used when initializing the signin process. This encapsulates the `IDXClient.start()` API call.
class IDXStartViewController: UIViewController, IDXSigninController {
    var signin: Signin?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        guard let signin = signin else {
            showError(SigninError.genericError(message: "Signin session deallocated"))
            return
        }
        
        signin.idx.start { [weak self] (response, error) in
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
}
