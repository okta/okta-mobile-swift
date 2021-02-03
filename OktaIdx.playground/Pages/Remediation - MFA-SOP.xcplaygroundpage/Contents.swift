/*:
 [Previous](@previous)

 # Remediation / MFA scenarios with Okta sign-on policy
 
 Complicated remediation scenarios, including authenticator enrolment, is possible with IDX. This process is more involved than simple username/password authentication since many mnore steps are required to proceed through the workflow. The process is highly metadata-driven, and real-world uses will involve the client building out UI elements to collect data from the user.
 
 For the purpose of this tutorial, we'll make some assumptions about what steps will occur. This workflow looks like so:
 
 1. Initialize the client
 2. Start the authentication workflow
 3. Supply the username.
 4. Supply the passcode credentials.
 5. Enroll the user for the enabled authenticators.
 6. Repeat until all enabled authenticators have been verified.
 7. Exchange the success response with access tokens.

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
var expectation = helper.expectation(for: "Start")

var response: IDXClient.Response?
client.start() { (responseObj, error) in
    guard let responseObj = responseObj else {
        helper.handle(expectation, error: error)
        return
    }

    response = responseObj
    expectation.fulfill()
}
helper.wait(for: expectation)

/*:
 ### Processing the remediation response
 
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
expectation = helper.expectation(for: "Identify")
identifyOption.proceed(using: params) { (responseObj, error) in
    guard let responseObj = responseObj else {
        helper.handle(expectation, error: error)
        return
    }
    
    response = responseObj
    expectation.fulfill()
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
params = IDXClient.Remediation.Parameters()
params[selectAuthenticatorField] = passcodeOption

expectation = helper.expectation(for: "Select authenticator option")
selectAuthenticator.proceed(using: params) { (responseObj, error) in
    guard let responseObj = responseObj else {
        helper.handle(expectation, error: error)
        return
    }
    
    response = responseObj
    expectation.fulfill()
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

params = IDXClient.Remediation.Parameters()
params[passcodeField] = helper.showPrompt(for: "Password")

expectation = helper.expectation(for: "Challenge")
passcodeAuthenticator.proceed(using: params) { (responseObj, error) in
    guard let responseObj = responseObj else {
        helper.handle(expectation, error: error)
        return
    }
    
    response = responseObj
    expectation.fulfill()
}
helper.wait(for: expectation)

/*:
 ## Selecting another authenticator

 For multifactor workflows, typically an additional authenticator is required. In this scenario, we're expecting the user to require email verification.  So in this next step, we're going to select the Email option.
 */
guard let selectEmailAuthenticator = response?.remediation?["select-authenticator-authenticate"],
      let selectEmailAuthenticatorField = selectEmailAuthenticator["authenticator"],
      let emailOption = selectEmailAuthenticatorField.options?.filter({ $0.label == "Email" }).first else
{
    throw helper.handle(error: "Could not find email authenticator option")
}

//: To choose which authenticator option we want to use, we simply assign the chosen option to the authenticator field.
params = IDXClient.Remediation.Parameters()
params[selectEmailAuthenticatorField] = emailOption

expectation = helper.expectation(for: "Select authenticator option")
selectEmailAuthenticator.proceed(using: params) { (responseObj, error) in
    guard let responseObj = responseObj else {
        helper.handle(expectation, error: error)
        return
    }
    
    response = responseObj
    expectation.fulfill()
}
helper.wait(for: expectation)

/*:
 ## Submitting the email verification code
 
 We'll be greeted with another challenge authenticator, but this time it will be expecting an email verification code. Like the passcode challenge authenticator, this one will use nested fields, though here it will be for the email verification code that is sent separately.
 */
guard let emailAuthenticator = response?.remediation?["challenge-authenticator"],
      let emailPasscodeField = emailAuthenticator["credentials"]?["passcode"] else
{
    throw helper.handle(error: "Could not find passcode form values")
}

params = IDXClient.Remediation.Parameters()
params[emailPasscodeField] = helper.showPrompt(for: "Email code")

expectation = helper.expectation(for: "Challenge")
emailAuthenticator.proceed(using: params) { (responseObj, error) in
    guard let responseObj = responseObj else {
        helper.handle(expectation, error: error)
        return
    }
    
    response = responseObj
    expectation.fulfill()
}
helper.wait(for: expectation)

/*:
 ## Selecting a security question
 
 When enforcing a security question policy, a user may be requested to choose a security question before they can complete their authentication.
 
 This response includes a `select-authenticator-enroll` option that requests the user supplies a security question.
 */
guard let selectEnrollmentAuthenticator = response?.remediation?["select-authenticator-enroll"],
      let selectEnrollmentField = selectEnrollmentAuthenticator["authenticator"],
      let questionOption = selectEnrollmentField.options?.filter({ $0.label == "Security Question" }).first else
{
    throw helper.handle(error: "Could not find security question enrollment option")
}

/*:
 Before we can receive the enrollment form, where the user can select their security question, they need to submit a request to select the Security Question enrollment.
 */
params = IDXClient.Remediation.Parameters()
params[selectEnrollmentField] = questionOption

expectation = helper.expectation(for: "Select security question enrollment option")
selectEnrollmentAuthenticator.proceed(using: params) { (responseObj, error) in
    guard let responseObj = responseObj else {
        helper.handle(expectation, error: error)
        return
    }
    
    response = responseObj
    expectation.fulfill()
}
helper.wait(for: expectation)

/*:
 ## Enrolling in the security question authenticator
 
 The security question enrollment form can be fairly complex, and can include multiple nested options, both for either selecting from a predefined set of security questions, or to supply their own question and answer.  For simplicity, we'll simply select a question at random.
 */
guard let enrollOption = response?.remediation?["enroll-authenticator"],
      let credentials = enrollOption["credentials"],
      let createQuestionOption = credentials.options?.filter({ $0.label == "Create my own security question" }).first,
      let questionField = createQuestionOption["question"],
      let answerField = createQuestionOption["answer"] else
{
    throw helper.handle(error: "Could not find security question authenticator fields")
}

//: Before we can receive the enrollment form, where the user can select their security question, they need to submit a request to select the Security Question enrollment.
params = IDXClient.Remediation.Parameters()
params[credentials] = questionOption
params[questionField] = "What is my favorite CIAM service?"
params[answerField] = "Okta"

expectation = helper.expectation(for: "Select security question enrollment option")
enrollOption.proceed(using: params) { (responseObj, error) in
    guard let responseObj = responseObj else {
        helper.handle(expectation, error: error)
        return
    }
    
    response = responseObj
    expectation.fulfill()
}
helper.wait(for: expectation)

/*:
 ## Skipping additional authenticator steps
 
 Some authenticator selections are optional, and can be skipped. This is represented by the `currentAuthenticatorEnrollment` property on the `IDXClient.Response` object. If a user wishes to skip additional authenticator enrollments, they can choose to do so by calling `proceed` on the appropriate option. In this sample, we'll choose to skip over the current option to continue to a successful login.
 */
guard let skipOption = response?.remediation?["skip"] else {
    throw helper.handle(error: "Could not find the \"skip\" option")
}

expectation = helper.expectation(for: "Skip subsequent enrollments")
skipOption.proceed() { (responseObj, error) in
    guard let responseObj = responseObj else {
        helper.handle(expectation, error: error)
        return
    }
    
    response = responseObj
    expectation.fulfill()
}
helper.wait(for: expectation)

/*:
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
