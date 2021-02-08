/*:
 [Previous](@previous)

 # Remediation: Polling for email verification using a magic link
 
 When users receive an email to verify their account, the email contains a verification code as well as a "magic link". Instead of requiring users to copy-and-paste the code into your application, you can support verifying an authenticator by using that link. This works through the use of polling an API endpoint until the user verifies their identity by clicking the magic link. This can be used in conjunction with the verification code, allowing your user to choose which method is more appropriate for them.
 
 ![Sample verification email](EmailExample.png "Sample verification email")
 
 Once the "Sign In" link is clicked, regardless of which device it is opened, the IDX authentication workflow can continue.

 ## Initializing the client

 As usual, you should configure and initialize the client and start the authentication workflow.
 */
import Foundation
import OktaIdx

let config = IDXClient.Configuration(issuer: "https://<#domain#>/",
                                     clientId: "<#client id#>",
                                     clientSecret: nil,
                                     scopes: ["openid", "email"],
                                     redirectUri: "<#redirect uri#>")
let client = IDXClient(configuration: config)

let helper = PlaygroundHelper()
var expectation = helper.expectation(for: "Start")

var response: IDXClient.Response?
client.start() { (responseObj, error) in
    defer { expectation.fulfill() }
    guard let responseObj = responseObj else {
        helper.handle(error: error)
        return
    }

    response = responseObj
}
helper.wait(for: expectation)

/*:
 ### Logging in with a username and password
 
 The response object can contain multiple remediation options. In the case of password authentication, we're interested in the "identify" remediation option. This object describes the form and set of values necessary to fulfill this remediation step. To supply the username, we pull out the "identifier" field.
 */
guard let identifyOption = response?.remediation?[.identify],
      let identifierField = identifyOption["identifier"] else
{
    throw helper.handle(error: "Could not find identifier form values")
}

/*:
 In this example, you can see how we can take advantage a convenience initializer to simplify the creation of a `Parameters` object. In this way, we can proceed to the `identify` remediation option to input the username.
 */
var username = helper.showPrompt(for: "Username")
expectation = helper.expectation(for: "Identify")
identifyOption.proceed(with: .init([identifierField: username])) { (responseObj, error) in
    defer { expectation.fulfill() }
    guard let responseObj = responseObj else {
        helper.handle(error: error)
        return
    }
    
    response = responseObj
}
helper.wait(for: expectation)

/*:
 ## Selecting an authenticator

 When going through a multifactor authentication workflow, the user may have several options to choose from to verify their account. For example, Email, Password, Security Question, etc.
 
 In this example, we'll select the Password challenge and proceed.
 */
guard let selectAuthenticator = response?.remediation?["select-authenticator-authenticate"],
      let selectAuthenticatorField = selectAuthenticator["authenticator"],
      let passcodeOption = selectAuthenticatorField.options?.filter({ $0.label == "Password" }).first else
{
    throw helper.handle(error: "Could not find passcode authenticator option")
}

//: To choose which authenticator option we want to use, we simply assign the chosen option to the authenticator field.
expectation = helper.expectation(for: "Select authenticator option")
selectAuthenticator.proceed(with: .init([selectAuthenticatorField: passcodeOption])) { (responseObj, error) in
    defer { expectation.fulfill() }
    guard let responseObj = responseObj else {
        helper.handle(error: error)
        return
    }
    
    response = responseObj
}
helper.wait(for: expectation)

/*:
 ## Submitting the user's password
 
 As in the [Passcode login](Passcode%20Login) flow, the `challenge-authenticator` remedation option is where a user can supply their credentials. We'll do the same thing here.
 */
guard let passcodeAuthenticator = response?.remediation?["challenge-authenticator"],
      let passcodeField = passcodeAuthenticator["credentials"]?["passcode"] else
{
    throw helper.handle(error: "Could not find passcode form values")
}

let password = helper.showPrompt(for: "Password")

expectation = helper.expectation(for: "Challenge")
passcodeAuthenticator.proceed(with: .init([passcodeField: password])) { (responseObj, error) in
    defer { expectation.fulfill() }
    guard let responseObj = responseObj else {
        helper.handle(error: error)
        return
    }
    
    response = responseObj
}
helper.wait(for: expectation)

/*:
 ## Selecting another authenticator

 For multifactor workflows, typically an additional authenticator is required. In this scenario, we're expecting the user to require email verification.  So in this next step, we're going to select the Email option.
 
 To choose which authenticator option we want to use, we simply assign the chosen option to the authenticator field, and proceed.
 */
if let selectEmailAuthenticator = response?.remediation?["select-authenticator-authenticate"],
   let selectEmailAuthenticatorField = selectEmailAuthenticator["authenticator"],
   let emailOption = selectEmailAuthenticatorField.options?.filter({ $0.label == "Email" }).first
{
    expectation = helper.expectation(for: "Select authenticator option")
    selectEmailAuthenticator.proceed(with: .init([selectEmailAuthenticatorField: emailOption])) { (responseObj, error) in
        defer { expectation.fulfill() }
        guard let responseObj = responseObj else {
            helper.handle(error: error)
            return
        }
        
        response = responseObj
    }
    helper.wait(for: expectation)
}

/*:
 ## Polling for the email verification "Magic Link"
 
 Once we select the email authenticator, a message will be sent to the user's email address. In the IDX response we have remediation options that can be used to submit the verification code, as described in [the MFA remediation page](Remediation%20-%20MFA-SOP). In addition to this, there is a `currentAuthenticatorEnrollment` property on the response, which provides additional information about the enrollment currently selected.
 
 This authenticator, when available, includes information about the polling frequency to use.
 
 - Note: Make sure, when you receive the verification email, that you click on the link to continue through to the next step.
 */
var poll = response?.currentAuthenticatorEnrollment?.poll
while poll != nil {
    expectation = helper.expectation(for: "Poll")
    guard let refreshTime = poll?.refresh else {
        throw helper.handle(error: "Poll option doesn't have a refresh interval")
    }
    
    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + refreshTime) {
        poll?.proceed { (pollResponse, error) in
            guard let pollResponse = pollResponse else {
                helper.handle(error: error)
                return
            }
            
            response = pollResponse
            expectation.fulfill()
        }
    }
    helper.wait(for: expectation)
    poll = response?.currentAuthenticatorEnrollment?.poll
}

/*:
 As you can see in the above code, in order to properly implement magic link polling, your application should continually proceed through that option, ensuring to respect the `refresh` interval. As long as the response's `currentAuthenticatorEnrollment` object has a nonnull `poll` value, that's an indication that the application should continue polling.
 
 Once the `poll` property is `nil`, it is safe to continue remediation. In this scenario, we use the `isLoginSuccessful` property of the `IDXClient.Response` object to indicate that login is successful.

 If it is, we can use the `exchangeCode` method to exchange the remediation response with a set of access tokens.
 */
guard response?.isLoginSuccessful ?? false else {
    throw helper.handle(error: "Login was unsuccessful")
}

expectation = helper.expectation(for: "Exchange code")
var token: IDXClient.Token?
response?.exchangeCode { (tokenObj, error) in
    defer { expectation.fulfill() }
    guard let tokenObj = tokenObj else {
        helper.handle(error: error)
        return
    }

    token = tokenObj
}
helper.wait(for: expectation)

/*:
 ## Using the Token response

 If all works well, you should see an `IDXClient.Token` object, populated with the appropriate credentials.
 */
print("Access token: \(token?.accessToken ?? "No token")")

helper.finish()

//: [Next](@next)
