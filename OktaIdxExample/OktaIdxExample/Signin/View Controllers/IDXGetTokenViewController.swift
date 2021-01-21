//
//  IDXGetTokenViewController.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-08.
//

import UIKit
import OktaIdx
import Combine

/// Sign in view controller used when login is successful, and encapsulates the `IDXClient.Response.getToken()` method.
class IDXGetTokenViewController: UIViewController, IDXResponseController {
    var signin: Signin?
    var response: IDXClient.Response?

    private var cancelObject: AnyCancellable?
    
    deinit {
        cancelObject?.cancel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let signin = signin,
              let response = response else
        {
            showError(SigninError.genericError(message: "Signin session or response is missing"))
            return
        }
        
        cancelObject = response.exchangeCode().receive(on: RunLoop.main).sink { (completion) in
            switch completion {
            case .failure(let error):
                self.showError(error)
                signin.failure(with: error)
            case .finished: break
            }
        } receiveValue: { (response) in
            signin.success(with: response)
        }
    }
}
