//
//  Signin.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-11.
//

import UIKit
import Combine
import OktaIdx

enum SigninError: Error {
    case genericError(message: String)
    case stepUnsupported
}

/// Signin wrapper that uses the Okta IDX client to step through the series
/// of remediation steps necessary to sign a user in.
public class Signin {
    private let storyboard: UIStoryboard
    private var promise: Future<IDXClient.Token, Error>.Promise?
    private var navigationController: UINavigationController?
    
    internal let idx: IDXClient
    
    /// Initializes a signin instance with the given client configuration.
    /// - Parameter configuration: Client app configuration.
    init(using configuration: IDXClient.Configuration) {
        idx = IDXClient(configuration: configuration)
        self.storyboard = UIStoryboard(name: "IDXSignin", bundle: Bundle(for: type(of: self)))
    }
    
    /// Begins the signin UI, presented from the given presenting view controller.
    /// - Parameter viewController: View controller to modally present the sign in navigation controller from.
    /// - Returns: Future to represent the completion of the signin process.
    public func signin(from viewController: UIViewController) -> Future<IDXClient.Token, Error> {
        return Future<IDXClient.Token, Error> { (promise) in
            guard let controller = self.storyboard.instantiateViewController(identifier: "start") as? IDXStartViewController else {
                promise(.failure(SigninError.genericError(message: "Cannot find story board controller \"start\"")))
                return
            }
            
            controller.signin = self
            self.promise = promise
            
            let navigationController = UINavigationController(rootViewController: controller)
            self.navigationController = navigationController
            
            viewController.present(navigationController, animated: true, completion: nil)
        }
    }
    
    /// Called by each view controller once their remediation step has been completed, allowing it to proceed to the next step of the workflow.
    /// - Parameter response: IDX response object received from the API.
    internal func proceed(to response: IDXClient.Response) {
        guard let navigationController = navigationController else {
            failure(with: SigninError.genericError(message: "Navigation controller undefined"))
            return
        }
        
        guard let controller = controller(for: response) else {
            failure(with: SigninError.genericError(message: "Could not find a controller for this response"))
            return
        }
        
        navigationController.setViewControllers([controller], animated: true)
    }
    
    /// Initializes the appropriate view controller for this response.
    /// - Parameter response: IDX client response that needs a view controller.
    /// - Returns: View controller to display, or `nil` if no controller was available
    private func controller(for response: IDXClient.Response) -> UIViewController? {
        // If the login is successful, there are no remediation options left. In this case,
        // we create a view controller to show the progress as a token is exchanged.
        if response.isLoginSuccessful {
            guard let controller = storyboard.instantiateViewController(identifier: "get-token") as? IDXGetTokenViewController else { return nil }
            controller.signin = self
            controller.response = response
            
            return controller
        }
        
        // Attempt to instantiate a view controller to represent the remediation option.
        guard let option = response.remediation?.remediationOptions.first else { return nil }
        
        if let controller = storyboard.instantiateViewController(identifier: "remediation") as? IDXRemediationTableViewController {
            controller.signin = self
            controller.response = response
            controller.remediationOption = option
            return controller
        }

        return nil
    }
    
    /// Called by the signin view controllers when the Future should fail.
    /// - Parameter error: The error to pass to the future.
    internal func failure(with error: Error) {
        navigationController?.dismiss(animated: true) {
            defer { self.promise = nil }
            self.promise?(.failure(error))
        }
    }
    
    /// Called by the signin view controllers when the Future should succeed.
    /// - Parameter token: The token produced at the end of the signin process.
    internal func success(with token: IDXClient.Token) {
        navigationController?.dismiss(animated: true) {
            defer { self.promise = nil }
            self.promise?(.success(token))
        }
    }
}
