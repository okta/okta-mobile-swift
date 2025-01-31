//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import Foundation
import ArgumentParser
import OktaOAuth2

@main
struct JWTSignin: AsyncParsableCommand {
    @Option(
        name: [.long, .short],
        help: "The application's issuer URL.")
    var issuer: URL
    
    @Option(name: [.long, .short], help: "The application's client ID.")
    var clientId: String
    
    @Option(name: [.long, .short], help: "The scopes to use.")
    var scope: String = "openid profile"
    
    @Option(
        name: [.long, .short],
        help: "JWT assertion string to use",
        transform: JWT.init(_:))
    var assertion: JWT?
    
    @Argument(
        help: "A file containing the JWT assertion. If `-` it reads from stdin.",
        completion: .file(),
        transform: URL.init(fileURLWithPath:))
    var file: URL? = nil
    
    mutating func validate() throws {
        if assertion == nil, file == nil {
            throw ValidationError("You must supply one of --inputFile or --assertion.")
        }
        
        guard assertion != nil || file != nil
        else {
            throw ValidationError("You can not use both --inputFile and --assertion.")
        }
        
        if assertion == nil {
            assertion = try JWT(try assertionString())
        }
    }
    
    mutating func run() async throws {
        guard let assertion = assertion else {
            throw ValidationError("Invalid assertion supplied")
        }
        
        let flow = JWTAuthorizationFlow(issuerURL: issuer,
                                        clientId: clientId,
                                        scope: scope)
        let token = try await flow.start(with: assertion)
        printUserInfo(using: token)
    }
    
    func printUserInfo(using token: Token) {
        if let idToken = token.idToken {
            print("""
            Name: \(idToken.name ?? "N/A")
            Locale: \(idToken.userLocale?.identifier ?? "N/A")
            Timezone: \(idToken.timeZone?.identifier ?? "N/A")
            
            Username: \(idToken.preferredUsername ?? "N/A")
            User ID: \(idToken.subject ?? "N/A")
            """)
        } else {
            print("No ID token returned.")
        }
    }
}
