/*:
 [Previous](@previous)

 # Managing authentication workflow using delegation API
 
 Since the IDX API is inherently metadata-driven, changes in policy or workflow may cause the client to need to follow different remediation steps. To accommodate the common iOS delegation pattern, IDXClient supports a delegate API to allow the authentication workflow to centralize behavior
 
 ## Defining the delegate implementation
  
 Whichever object conforms to the `IDXClientDelegate` protocol can use these methods to intercept responses, centralizing the behavior for how to respond to certain requests. This example is simple, but it can be as complicated as necessary to ensure your sign in behavior reflects your application's needs.
 */
import OktaIdx

class LoginSession: IDXClientDelegate {
    let username: String
    let password: String
    let completion: (IDXClient.Token?, Error?) -> Void
    
    enum LoginError: Error {
        case serverError(message: String)
        case unknownResponse
    }
    
    init(username: String,
         password: String,
         completion: @escaping (IDXClient.Token?, Error?) -> Void)
    {
        self.username = username
        self.password = password
        self.completion = completion
    }
    
    func idx(client: IDXClient, didReceive error: Error) {
        completion(nil, error)
    }
    
    func idx(client: IDXClient, didReceive response: IDXClient.Response) {
        guard response.isLoginSuccessful == false else {
            response.exchangeCode(completion: nil)
            return
        }
        
        if let message = response.messages?.first {
            completion(nil, LoginError.serverError(message: message.message))
            return
        }
        
        if let option = response.remediation?[.identify],
           let field = option["identifier"]
        {
            option.proceed(with: .init([field: username]), completion: nil)
        }
        
        else if let option = response.remediation?[.challengeAuthenticator],
                let field = option["credentials"]?["passcode"]
        {
            option.proceed(with: .init([field: password]), completion: nil)
        }
        
        else {
            completion(nil, LoginError.unknownResponse)
        }
    }
    
    func idx(client: IDXClient, didExchangeToken token: IDXClient.Token) {
        completion(token, nil)
    }
}

/*:
 - Note:
 In the above class, you may notice that none of the calls to `proceed` or `exchangeCode` perform any logic within the completion handlers. Instead of nesting logic within completion blocks, this approach relies on the client calling the delegate when responses are received. This enables the `LoginSession` class to manage the authentication flow in a central place.

 ## Create and assign the delegate
 
 Once your delegate is defined, you can assign it to the IDXClient. In this example, the `LoginSession` class conforms to the `IDXClientDelegate` protocol, allowing it to receive updates from the `IDXClient` as responses are received.
 */
let helper = PlaygroundHelper()
let expectation = helper.expectation(for: "Authenticate")

var token: IDXClient.Token?

let loginDelegate = LoginSession(username: "<#username#>",
                                 password: "<#password#>") { (result, error) in
    defer { expectation.fulfill() }
    guard let result = result else {
        print("An error occurred: \(error?.localizedDescription ?? "unknown")")
        return
    }
    
    token = result
}

let config = IDXClient.Configuration(issuer: "https://<#domain#>/",
                                     clientId: "<#client id#>",
                                     clientSecret: nil,
                                     scopes: ["openid", "email"],
                                     redirectUri: "<#redirect uri#>")
let client = IDXClient(configuration: config)
client.delegate = loginDelegate

/*:
 ## Beginning the sign on flow

 Once you initiate the sign in flow, the individual completion handlers don't need to directly process the responses. This can be left to the delegate, if necessary. Furthermore, any intermediate responses will be handled by the delegate in this instance, so no further async waits are required in this playground page. Additionally, the completion handler isn't necessary in this instance, because all response handling is handled by the delegate.
 */
client.start(completion: nil)
helper.wait(for: expectation)

/*:
 ## Using the Token response
 
 If all works well, you should see an `IDXClient.Token` object, populated with the appropriate credentials.
 */
print("Access token: \(token?.accessToken ?? "No token")")

helper.finish()

//: [Next](@next)
