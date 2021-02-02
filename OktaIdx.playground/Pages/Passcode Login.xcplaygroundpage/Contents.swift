/*:
 [Previous](@previous)

 # Authenticating with username & password
 
 When using username and password to authenticate, the process is typically broken into two steps:
 
 1. Initialize the client
 2. Start the authentication workflow
 3. Supply the username and proceed to the passcode challenge.
 4. Supply the passcode credentials and proceed to a successful response.
 5. Exchange the success response with access tokens.

 This process is asynchronous, so each call must be handled in the appropriate completion handler.
 
 ## Initializing the client

 As usual, you should configure and initialize the client to initiate the process.
 */

import OktaIdx

let config = IDXClient.Configuration(issuer: "https://<#domain#>/",
                                     clientId: "<#client id#>",
                                     clientSecret: nil,
                                     scopes: ["openid", "email"],
                                     redirectUri: "<#redirect uri#>")
let client = IDXClient(configuration: config)

/*:
 ## Starting the authentication workflow
 
 To begin authenticating a user, you first call the `start()` method on the `IDXClient`. This asynchronously calls the IDX API, and if the client configuration is valid, you will get an `IDXClient.Response` object that describes the available remediation steps to authenticate the user.
 */
let helper = PlaygroundHelper()
let startExpectation = helper.expectation(for: "Start")

var response: IDXClient.Response?
client.start() { (responseObj, error) in
    guard let responseObj = responseObj else {
        helper.handle(startExpectation, error: error)
        return
    }

    response = responseObj
    startExpectation.fulfill()
}
helper.wait(for: startExpectation)

/*:
 ## Identifying the user with their username
 
 The response object can contain multiple remediation options. In the case of password authentication, we're interested in the "identify" remediation option. This object describes the form and set of values necessary to fulfill this remediation step. To supply the username, we pull out the "identifier" field.
 */
guard let identifyOption = response?.remediation?["identify"],
      let identifierField = identifyOption["identifier"] else
{
    throw helper.handle(error: "Could not find identifier form values")
}

/*:
 While it's possible to submit JSON data directly to the remediation option, it is often simpler to use the `Parameters` helper object to supply values to the appropriate fields. In the following code sample, we use the `identifierField` we retrieved earlier and supply the username to that field.
 */
var params = IDXClient.Remediation.Parameters()
params[identifierField] = helper.showPrompt(for: "Username")

/*:
 ### Proceeding to the next remediation step
 
 Once you have the parameters ready, you can proceed to the next remediation step. This allows the server to process our user's response, and will then return a new response object that describes the next steps available. In this case, the next step should hopefully be a remediation step where a user can supply their password.
 */
let identifyExpectation = helper.expectation(for: "Identify")
identifyOption.proceed(using: params) { (responseObj, error) in
    guard let responseObj = responseObj else {
        helper.handle(identifyExpectation, error: error)
        return
    }

    response = responseObj
    identifyExpectation.fulfill()
}
helper.wait(for: identifyExpectation)

/*:
 ## Submitting the user's password
 
 The `challenge-authenticator` remedation option is where a user can supply their credentials. In this code sample, we attempt to retrieve that remediation option, and extract the passcode field. As you can see, this is an example of a nested set of form values.
 */
guard let authenticatorOption = response?.remediation?["challenge-authenticator"],
      let passcodeField = authenticatorOption["credentials"]?["passcode"] else
{
    throw helper.handle(error: "Could not find passcode form values")
}

/*:
 We create a new `Parameters` object, and supply the user's password to the passcode field. Then, we proceed to the authenticator remediation option.
 */
params = IDXClient.Remediation.Parameters()
params[passcodeField] = helper.showPrompt(for: "Password")
    
let challengeExpectation = helper.expectation(for: "Challenge")
authenticatorOption.proceed(using: params) { (responseObj, error) in
    guard let responseObj = responseObj else {
        helper.handle(challengeExpectation, error: error)
        return
    }
    
    response = responseObj
    challengeExpectation.fulfill()
}
helper.wait(for: challengeExpectation)

/*:
 ## Exchanging the successful response with access tokens
 
 Assuming we don't get an error when submitting the user's password, we should hopefully be greeted with a successful login. We use the `isLoginSuccessful` property of the `IDXClient.Response` object to indicate that login is successful.
 
 If it is, we can use the `exchangeCode` method to exchange the remediation response with a set of access tokens.
 */
guard response?.isLoginSuccessful ?? false else {
    throw helper.handle(error: "Login was unsuccessful")
}

let exchangeExpectation = helper.expectation(for: "Exchange code")
var token: IDXClient.Token?
response?.exchangeCode { (tokenObj, error) in
    guard let tokenObj = tokenObj else {
        helper.handle(exchangeExpectation, error: error)
        return
    }
    
    token = tokenObj
    exchangeExpectation.fulfill()
}
helper.wait(for: exchangeExpectation)

/*:
 ## Using the Token response
 
 If all works well, you should see an `IDXClient.Token` object, populated with the appropriate credentials.
 */
print("Access token: \(token?.accessToken ?? "No token")")

helper.finish()

//: [Next](@next)
