//
//  IDXStartViewController.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-08.
//

import UIKit
import OktaIdx
import Combine

/// Sign in controller used when initializing the signin process. This encapsulates the `IDXClient.start()` API call.
class IDXStartViewController: UIViewController, IDXSigninController {
    var signin: Signin?

    private var cancelObject: AnyCancellable?
    
    deinit {
        cancelObject?.cancel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        guard let signin = signin else {
            showError(SigninError.genericError(message: "Signin session deallocated"))
            return
        }
        
        cancelObject = signin.idx.start().receive(on: RunLoop.main).sink { (completion) in
            switch completion {
            case .failure(let error):
                self.showError(error)
                signin.failure(with: error)
            case .finished: break
            }
        } receiveValue: { (response) in
            signin.proceed(to: response)
        }
    }
}
