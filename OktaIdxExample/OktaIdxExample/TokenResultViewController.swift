//
//  TokenResultViewController.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-11.
//

import UIKit
import OktaIdx

class TokenResultViewController: UIViewController {
    var token: IDXClient.Token?
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let token = token else {
            textView.text = "No token was found"
            return
        }
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byCharWrapping
        paragraph.paragraphSpacing = 15
        
        let bold = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)]
        let normal = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body),
                      NSAttributedString.Key.paragraphStyle: paragraph]
        
        func addString(to string: NSMutableAttributedString, title: String, value: String) {
            string.append(NSAttributedString(string: "\(title):\n", attributes: bold))
            string.append(NSAttributedString(string: "\(value)\n", attributes: normal))
        }
        
        let string = NSMutableAttributedString()
        addString(to: string, title: "Access token", value: token.accessToken)
        
        if let refreshToken = token.refreshToken {
            addString(to: string, title: "Refresh token", value: refreshToken)
        }
        
        addString(to: string, title: "Expires in", value: "\(token.expiresIn) seconds")
        addString(to: string, title: "Scope", value: token.scope)
        addString(to: string, title: "Token type", value: token.tokenType)
        
        if let idToken = token.idToken {
            addString(to: string, title: "ID token", value: idToken)
        }
        
        textView.attributedText = string
    }
}
