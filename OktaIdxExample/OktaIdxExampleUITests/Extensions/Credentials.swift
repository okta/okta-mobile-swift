//
//  Credentials.swift
//  OktaIdxExampleUITests
//
//  Created by Mike Nachbaur on 2021-01-21.
//

import Foundation

struct TestCredentials {
    enum Scenario {
        case passcode, mfasop
        
        internal var prefix: String {
            switch self {
            case .passcode: return "PASSCODE"
            case .mfasop: return "MFASOP"
            }
        }
        
        var usernameKey: String {
            return "\(prefix)_USERNAME"
        }

        var passwordKey: String {
            return "\(prefix)_PASSWORD"
        }
    }
    let username: String
    let password: String
    let clientId: String
    let issuer: String
    let redirectUri: String
    var issuerUrl: String {
        return "https://\(issuer)"
    }

    init?(with scenario: Scenario) {
        let env = ProcessInfo.processInfo.environment
        guard let clientId = env["CLIENT_ID"],
              let issuer = env["ISSUER_DOMAIN"],
              let redirectUri = env["REDIRECT_URI"],
              let username = env[scenario.usernameKey],
              let password = env[scenario.passwordKey] else
        {
            return nil
        }
        
        guard clientId != "",
              issuer != "",
              redirectUri != "",
              username != "",
              password != "" else
        {
            return nil
        }
        
        self.clientId = clientId
        self.issuer = issuer
        self.redirectUri = redirectUri
        self.username = username
        self.password = password
    }
}
