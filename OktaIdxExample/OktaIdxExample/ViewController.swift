//
//  ViewController.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-04.
//

import UIKit
import Combine
import OktaIdx

class ViewController: UIViewController {
    private static let issuerUrlKey = "issuerUrl"
    private static let clientIdKey = "clientId"
    private static let redirectUrlKey = "redirectUrl"

    @IBOutlet weak var issuerField: UITextField!
    @IBOutlet weak var clientIdField: UITextField!
    @IBOutlet weak var redirectField: UITextField!
    private var cancelObject: AnyCancellable?
    
    deinit {
        cancelObject?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        issuerField.text = UserDefaults.standard.string(forKey: type(of: self).issuerUrlKey)
        clientIdField.text = UserDefaults.standard.string(forKey: type(of: self).clientIdKey)
        redirectField.text = UserDefaults.standard.string(forKey: type(of: self).redirectUrlKey)
    }
    
    func loginComplete(with token: IDXClient.Token) {
        print("Authenticated with \(token)")
    }

    func configuration() -> IDXClient.Configuration? {
        guard let issuerUrl = issuerField.text,
              let clientId = clientIdField.text,
              let redirectUri = redirectField.text else
        {
            return nil
        }
        
        return IDXClient.Configuration(issuer: issuerUrl,
                                       clientId: clientId,
                                       clientSecret: nil,
                                       scopes: ["openid", "profile", "offline_access"],
                                       redirectUri: redirectUri)
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

        UserDefaults.standard.setValue(issuerUrl, forKey: type(of: self).issuerUrlKey)
        UserDefaults.standard.setValue(clientId, forKey: type(of: self).clientIdKey)
        UserDefaults.standard.setValue(redirectUri, forKey: type(of: self).redirectUrlKey)
        UserDefaults.standard.synchronize()
        
        guard let config = configuration() else {
            return
        }
        
        cancelObject = Signin(using: config).signin(from: self).sink { (completion) in
            switch completion {
            case .failure(let error):
                print("Could not sign in: \(error)")
            case .finished: break
            }
        } receiveValue: { (token) in
            guard let controller = self.storyboard?.instantiateViewController(identifier: "TokenResult") as? TokenResultViewController else { return }
            controller.token = token
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}
