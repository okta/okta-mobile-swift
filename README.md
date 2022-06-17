[<img src="https://aws1.discourse-cdn.com/standard14/uploads/oktadev/original/1X/0c6402653dfb70edc661d4976a43a46f33e5e919.png" align="right" width="256px"/>](https://devforum.okta.com/)

[![Support](https://img.shields.io/badge/support-Developer%20Forum-blue.svg)][devforum]
[![API Reference](https://img.shields.io/badge/docs-reference-lightgrey.svg)][swiftdocs]

# Okta IDX Swift SDK

> :grey_exclamation: The use of this SDK requires usage of the Okta Identity Engine. This functionality is in general availability but is being gradually rolled out to customers. If you want to request to gain access to the Okta Identity Engine, please reach out to your account manager. If you do not have an account manager, please reach out to oie@okta.com for more information.

> This library is currently GA. See [release status](#release-status) for more information.

This library is built for projects written in Swift to communicate with Okta as an OAuth 2.0 + OpenID Connect provider. It works with [Okta's Identity Engine](https://developer.okta.com/docs/guides/oie-intro/) to authenticate and register users.

To see this library working in a sample, check out our [iOS Sample Application](Samples/EmbeddedAuthWithSDKs). You can also check out our guides for step-by-step instructions:

 * [Build with the embedded SDK](https://developer.okta.com/docs/guides/oie-embedded-common-run-samples/ios/main/#run-the-embedded-sdk-sample-app)


**Table of Contents**

<!-- TOC depthFrom:2 depthTo:3 -->
<!-- /TOC -->

## Release status

This library uses semantic versioning and follows Okta's [Library Version Policy][okta-library-versioning].

✔️ The current stable major version series is: 2.x

| Version | Status                             |
| ------- | ---------------------------------- |
| 1.0.0   |                                    |
| 2.0.1   | ✔️ Stable                           |

The latest release can always be found on the [releases page][github-releases].

## Need help?
 
If you run into problems using the SDK, you can:
 
* Ask questions on the [Okta Developer Forums][devforum]
* Post [issues][github-issues] here on GitHub (for code errors)

## Installation

To get started, you will need:

* An Okta account, called an _organization_ (sign up for a free [developer organization](https://developer.okta.com/signup) if you need one).
* Xcode targeting iOS 10 and above.

### Swift Package Manager

Add the following to the `dependencies` attribute defined in your `Package.swift` file. You can select the version using the `majorVersion` and `minor` parameters. For example:

```swift
dependencies: [
    .Package(url: "https://github.com/okta/okta-idx-swift.git", majorVersion: <majorVersion>, minor: <minor>)
]
```

### CocoaPods

Simply add the following line to your `Podfile`:

```ruby
pod 'OktaIdx'
```

Then install it into your project:

```bash
pod install --repo-update
```

## API patterns

The IDX SDK enables dynamic user authentication through a cyclical call-and-response pattern. A user is presented with a series of choices in how they can iteratively step through the authentication process, with each step giving way to additional choices until they can either successfully authenticate or receive actionable error messages.

Each step in the authentication process is represented by an `Response` object, which contains the choices they can take, represented by the `Remediation` class. Remediations provides metadata about its type, a form object tree that describes the fields and values that should be presented to the user, and other related data that helps you, the developer, build a UI capable of prompting the user to take action.

When a remediation is selected and its inputs have been supplied by the user, the `proceed()` method can be called on the remediation to proceed to the next step of the authentication process.  This returns another `Response` object, which causes the process to continue. 

> **Note:** Unless documented otherwise, all asynchronous functions accept either a Swift `Result` completion handler, or a conventional completion block that provides the response and error as separate values in the argument tuple.

## Usage

The below code snippets will help you understand how to use this library.

Once you initialize an `IDXClient`, you can call methods to make requests to the Okta IDX API. Please see the [configuration reference](#configuration-reference) section for more details.

### Create the client configuration

```swift
let config = IDXClient.Configuration(
    issuer: "https:///<#oktaDomain#>/oauth2/default", // e.g. https://foo.okta.com/oauth2/default, https://foo.okta.com/oauth2/ausar5vgt5TSDsfcJ0h7
    clientId: "<#clientId#>",
    clientSecret: nil, // Optional, only required for confidential clients.
    scopes: ["openid", "email", "offline_access", "<#otherScopes#>"],
    redirectUri: "<#redirectUri#>") // Must match the redirect uri in client app settings/console
```

> **Note:** While your issuer URL may vary for advanced configurations, for most uses it will be your Okta Domain, followed by `/oauth2/default`.

### Create the Client

```swift
IDXClient.start(with: configuration) { result in
    switch result {
    case .success(let response):
        // Handle the response
    case .failure(let error):
        // Handle the error
    }
}
```

### Start / continue the authentication session

```swift
client.resume { result in
    switch result {
    case .success(let response):
        // Use the response
    case .failure(let error):
        // Handle the error
    }
}
```

### Get new tokens using username & password

In this example the sign-on policy has no authenticators required.

> **Note:** Steps to identify the user might change based on your Org configuration.

```swift
func signIn(username: String, password: String, completion: @escaping(Token?, Error?) -> Void) {
    // Start the IDX authentication session
    IDXClient.start { (client, error) in
        guard let client = client else {
            completion(nil, error)
            return
        }

        // Call `resume` to load the initial response
        client.resume { (response, error) in {
            guard let response = response else {
                completion(nil, error)
                return
            }

            // Use the `identify` remediation option, and find the relevant form fields
            guard let remediation = response.remediations[.identify],
                  let usernameField = remediation["identifier"],
                  let passwordField = remediation["credentials.passcode"],
            else {
                completion(nil, error)
                return
            }
            
            // Populate the form fields with the user's supplied values
            usernameField.value = username
            passwordField.value = password
            
            // Proceed through the remediation option
            remediation.proceed { (response, error) in 
                guard let response = response,
                      response.isLoginSuccessful
                else {
                    completion(nil, error)
                }
                
                // Exchange the successful response for tokens
                response.exchangeCode { (token, error) in
                    completion(token, error)
                }
            }
        }
    }
}
```

### Cancel the OIE transaction and start a new one

*Note:* This example assumes this code is being called in response to a previous IDX API call.

```swift
response.cancel { (response, error) in
    // Handle the newly-restarted IDX session
}
```

### Remediation/MFA scenarios with sign-on policy

#### Selecting an authenticator factor during authentication or enrollment

When a user is asked to either enroll in a new authentication factor, or to authenticate against a previously-enrolled factor, a response may contain either the `.selectAuthenticatorEnroll` or `.selectAuthenticatorAuthenticate` remediation types. The usage patterns are similar for both.

##### Displaying the possible enrollment options to the user

```swift
if let remediation = response.remediations[.selectAuthenticatorEnroll],
   let authenticatorOptions = remediation["authenticator"]?.options
{
    for option in authenticatorOptions {
        guard let authenticator = option.authenticator else { continue }

        // Display a UI choice for this choice, optionally using
        // the `authenticator` associated with this option to provide
        // more context.
        self.showChoice(label: option.label)
    }
}
```

##### Selecting an authenticator

Once a user has made their choice, your application can apply that choice and proceed through the remediation.

```swift
let selectedChoice = "Security Question"
if let remediation = response.remediations[.selectAuthenticatorEnroll],
   let authenticator = remediation["authenticator"],
   let option = authenticator.options?.first(where: { field -> Bool in
    field.label == selectedChoice
   })
{
    authenticator.selectedOption = option
    remediation.proceed { (response, error) in
        // Handle the response to enroll in the authenticator
    }
}
```

#### Enrolling a Security Question authenticator

In this example, the org is configured to require a security question as a second authenticator. After answering the password challenge, users have to select *security question*, select a question, and enter an answer to finish the process.

> **Note:** In this example, it is assumed that the session has already been initiated, the username and password have been submitted, and the Security Question authenticator has been selected.  Please see the above section for more details.

```swift
guard let remediation = response.remediations[.enrollAuthenticator],
      let credentials = remediation["credentials"],
      let createQuestionOption = credentials.options?.first(where: { option in
        option.label == "Create my own security question"
      }),
      let questionField = createQuestionOption["question"],
      let answerField = createQuestionOption["answer"]
else {
    // Handle error
    return
}

credentials.selectedOption = createQuestionOption
questionField.value = "What is Trillian's real name?"
answerField.value = "Tricia MacMillan"

remediation.proceed { (response, error) in
    // Handle the response
}
```

#### Authenticating using an Email authenticator

In this example, the Org is configured to require an email as a second authenticator. After answering the password challenge, users have to select *email* and enter the code to finish the process.

When the email authenticator is selected by the user, a message is sent to their address containing a code. Out of band of your application, the user will load the email and will either copy & paste the code, or will input it by hand.

> **Note:** This example assumes the username and password have been submitted, and the Email authenticator has been selected.

```swift
guard let remediation = response.remediations[.challengeAuthenticator],
      let passcodeField = remediation["credentials.passcode"]
else {
    // Handle error
    return
}

passcodeField.value = "123456"
remediation.proceed { (response, error) in
    // Handle response
}
```

#### Enrolling a phone authenticator (SMS/Voice)

In this example, the Org is configured with phone as a second authenticator. After answering the password challenge, users have to provide a phone number and then enter a code to finish the process.

##### Selecting the SMS or Voice option

> **Note:** This example assumes the username and password have been submitted.

```swift
guard let remediation = response.remediations[.selectAuthenticatorEnroll],
      let authenticatorField = remediation["authenticator"],
      let phoneOption = authenticatorField.options?.first(where: { option in
          option.label == "Phone"
      }),
      let phoneNumberField = phoneOption["phoneNumber"],
      let methodTypeField = phoneOption["methodType"],
      let smsMethod = methodTypeField.options?.first(where: { option in
          option.label == "SMS"
      }) else
{
    // Handle error
    return
}

authenticatorField.selectedOption = phoneOption
methodTypeField.selectedOption = smsMethod
phoneNumberField.value = "+15551234567"

remediation.proceed { (response, error) in
    // Use this response to present the verification code UI to the user
}
```

##### Responding with the verification code

```swift
guard let remediation = response.remediations[.challengeAuthenticator],
      let passcodeField = remediation["credentials.passcode"],
else {
    // Handle error
    return
}

passcodeField.value = "123456"
remediation.proceed { (response, error) in
    // Handle response
}
```

### Sign up / Register

When you [configure and enable a self-service registration policy](https://developer.okta.com/docs/guides/set-up-self-service-registration/main/#enable-and-configure-a-self-service-registration-policy), the initial response will include a `.selectEnrollProfile` remediation option. Proceeding through this remediation option will return a remediation that will allow the user to supply their name and email address, allowing them to proceed through to creating a new user profile.

```swift
guard let remediation = response.remediations[.selectEnrollProfile] else {
    // Handle error
    return
}

remediation.proceed { (response, error) in
    guard let remediation = response?.remediations[.enrollProfile],
          let firstNameField = remediation["userProfile.firstName"],
          let lastNameField = remediation["userProfile.lastName"],
          let emailField = remediation["userProfile.email"]
    else {
        return
    }
    
    firstNameField.value = "Mary"
    lastNameField.value = "Smith"
    emailField.value = "msmith@example.com"
    remediation.proceed { (response, error) in
        // Handle response
    }
}
```

After the `.enrollProfile` remediation is successful, you can follow the subsequent remediations to enroll in authenticators to select a password, enroll in factors, and subsequently exchange a successful response for a token.

### Password recovery

Password recovery is supported through the use of the current authenticator's associated capabilities.  This can be accessed through the use of the response's `authenticators` collection. Not all authenticators have the same set of capabilities, so these additional features are exposed through related capabilities.  So those authenticators that can support account recovery, you can check to see if provides that capability.

```swift
if let recoverable = response.authenticators.current?.recoverable {
    recoverable.recover { result in
        // Handle the result
    }
}
```

Once you perform the `recover` action, the response you receive will contain a `.identifyRecovery` remediation option, which you can use to supply the user's identifier.

```swift
guard let response = response,
      let remediation = response.remediations[.identifyRecovery],
      let identifierField = remediation["identifier"]
else {
    // Handle error
    return
}

identifierField.value = "mary.smith@example.com"
remediation.proceed { (response, error) in
    // Handle the response
}
```

The subsequent responses will prompt the user to respond to different factor challenges to verify their account, and reset their password.
 
### Email verification polling

When using an email authenticator, the user will receive both a numeric code and a link to verify their identity. If the user clicks this link, it will verify the authenticator and the application can immediately proceed to the next remediation step.

*Note:* This code assumes that it is running in the same UI where the user is asked for their verification code.

```swift
guard let remediation = response.remediations[.challengeAuthenticator],
      let authenticator = remediation.authenticators[.email]
else {
    // Handle error
    return
}

if let pollable = authenticator.pollable {
    pollable.startPolling { result in
        // Use the result to display the UI for the next step
        // in the user's authentication, or handle the error.
    }
}

// Or, call `stopPolling()` to stop polling for the magic link.
```

### Check remediation options

Responses may contain multiple remediation options. There are multiple ways to identify which options are available.

```swift
// Select the option by its name using subscripting.
let remediation = response.remediations["challenge-authenticator"]

// Select the option by its enum type using subscripting.
let remediation = response.remediations[.challengeAuthenticator]

// Select the option by iterating over the options
let remediation = response.remediations.first(where: { $0.name == "challenge-authenticator" })
```

From this point, you can access the form values associated with it. 

### Working with remediation option forms

A remediation contains a form which may contain fields to display to the user or to accept user-input to submit to the server. 

```swift
remediation.form.forEach { formField in
    // Do something with the form field
}
```

For convenience, keyed subscripting is supported to access fields by name, using dot-notation to retrieve nested fields.

```swift
let identifierField = remediation["identifier"]
let passcodeField = remediation["credentials"]?.form?["passcode"]

// Or
let passcodeField = remediation["credentials.passcode"]
```

### Supplying values to remediation options

The purpose of using remediation options is to enable a user to make selections and supply user-data in response to these requests. The fields contain only two mutable properties that can be used to supply user data and make selections in the API.

#### Field values

When inputting user information, the field's `value` property can be used to pass this data into the API.

```swift
let identifierField = remediation["identifier"]
identifierField.value = "arthur.dent@example.com"
```

#### Multiple-choice selections

When multiple choices are presented to the user (e.g. selecting an authenticator, choosing from a predefined list of security questions, etc), a form field will contain a nested `options` array of fields defining the choices made.

To select a choice, simply assign the nested option to the `selectedOption` property of its parent.

```
guard let remediation = response.remediations[.selectAuthenticatorAuthenticate],
      let authenticatorField = remediation["authenticator"],
      let chosenOption = authenticatorField.options?.first(where: { option in
          option.label == "Email"
      })
{
    // Handle error
    return
}

authenticatorField.selectedOption = chosenOption
```

#### Using fields in your application

Since the fields not only describe how you can render your UI, but also accepts the values provided by the user, this lends itself as a convenient placeholder for user-supplied data while they populate their information into forms. Once all selections have been made, you can call the `proceed` method on the remediation option to submit their form data. 

```swift
import SwiftUI

struct UsernameView: View {
    @State var username: String = ""
    var remediation: Remediation
    var body: some View {
        Form {
            TextField("Username", text: $username, onCommit: {
                guard let field = self.remediation["identifier"] else { return }
                field.value = self.username
            })
            Button("Continue") {
                remediation.proceed()
            }
        }
    }
}
```

### Get tokens with a successful response

Whenever receiving a response, it's important to check the `isLoginSuccessful` property to determine if the user is able to complete their authentication. At this point, you may call the `exchangeCode` method on the response to receive a `Token`.

```swift
if response.isLoginSuccessful {
    response.exchangeCode { (token, error) in
        guard let token = token else {
            // Handle error
            return
        }

        // Use the token
    }
}
```

### Logout / revoking tokens

Logging a user out is as simple as revoking the token. As a developer, you have the choice to either revoke just the refresh token, or to revoke both access and refresh tokens. There are two ways one can revoke tokens, depending on how you implement the IDX SDK.

#### Revoking a token using an `Token` object

```swift
token.revoke(type: .accessAndRefreshToken) { (success, error) in
    if !success {
        // Handle error
    }
}
```

#### Revoking a token using a plain token string

If you don't store the `Token` object, you can make requests to revoke tokens with the raw string value of the token in question.

```swift
Token.revoke(token: tokenString,
                       type: .accessAndRefreshToken,
                       configuration: configuration) { (success, error) in
    if !success {
        // Handle error
    }
}
```

### Error handling

Errors are a natural part of authenticating a user, especially since there may be times where a username is mistyped, a password is forgotten, or the incorrect SMS verification code is provided. These sorts of errors _do not_ result in an `Error` object being returned to method closures. These are considered successful responses, because no error occurred in communicating with Okta, processing client credentials, or formulating `URLRequest`s.  Errors returned to these closures are typically errors in either a) network request handling, or b) incomplete form data supplied to remediations.  The `errorDescription` for these errors should describe the error that occurred.

All other non-fatal errors are reported through the use of the `MessageCollection` object that is associated with a) the Response, b) the Remediation, or c) individual Fields.  These can be considered to be user-facing error messages, and convey what the problem is, and potential steps the user can take to proceed.

#### Message collections

Since errors may occur at various places within the flow and a remediation form, the placement of these messages can vary; for example, if an email address is invalid when signing up for a new user, the error message may be tied to the form field itself. 

For convenience, the root-level message collection (accessible via the `Response.messages` property), aggregates all nested messages into the `allMessages` property.

```swift
response.messages.allMessages.forEach { message in
    // Display / process the message
}
```

Otherwise, root-level error messages (e.g. messages that are applicable to the entire authentication session, and not constrained to an individual remediation or form field), can be accessed generally through the messages collection.

```swift
response.messages.forEach { message in
    // Display the root-level message
}
```

If a message is tied to an individual form field, it will exist within the `allMessages` property of the root-level message collection, as well as in the field's `messages` property.

```swift
guard let identifierField = response?.remediations[.identify]?.identifier else { return }
if !identifierField.messages.isEmpty {
    identifierField.messages.forEach { message in
        // Display the field-level message
    }
}
```

#### Non-recoverable error states

There are circumstances when the authentication session may no longer be valid, and an error state is unrecoverable. For example, if the session has expired.

This situation can be determined when there are no remaining remediations. This essentially means that there are no actions the user can take to remediate their authentication session, and a new session should be created.

```swift
if response.remediations.isEmpty {
    // Handle non-recoverable error
}
```

### Responding to events using the IDXClientDelegate

IDXClient supports the use of a delegate to centralize response handling and processing. This enables a single delegate object to intercept all responses, errors, and tokens that are received by the client, regardless of where the initial call is made within your application.

The following example highlights how simple username/password authentication can be implemented using a delegate.

```swift
class LoginManager: IDXClientDelegate {
    private var client: IDXClient?
    let username: String
    let password: String
    
    func start() {
        IDXClient.start(configuration: config) { result in
            switch result {
            case .failure(let error):
                // Handle the error
            case .success(let client):
                self.client = client
                client.delegate = self
                client.resume()
            }
        }
    }
    
    func idx(client: IDXClient, didReceive response: Response) {
        // If login is successful, immediately exchange it for a token.
        guard !response.isLoginSuccessful else {
            response.exchangeCode()
            return
        }
        
        // Identify the user
        if let remediation = response.remediations[.identify] {
            remediation["identifier"]?.value = username
            remediation["credentials.passcode"]?.value = password
            remediation.proceed() 
        }
        
        // If the password is requested on a separate "page", supply it there.
        else if let remediation = response.remediations[.challengeAuthenticator],
                response.authenticators.current.type == .password
        {
            remediation["credentials.passcode"]?.value = password
            remediation.proceed()
        }
        
        // Handle other scenarios / remediation states here...
    }

    func idx(client: IDXClient, didReceive token: Token) {
        // Login succeeded, with the given token.
    }

    func idx(client: IDXClient, didReceive error: Error) {
        // Handle the error
    }
}
```

## Development

### Running Tests

To perform an end-to-end test, copy the `TestCredentials.xcconfig.example` file to `TestCredentials.xcconfig`, and update its contents to match your configuration as specified in the [prerequisites](#prerequisites). Next, you can run the test targets for both `okta-idx-ios` and `EmbeddedAuth` (in the [Samples/EmbeddedAuthWithSDKs](Samples/EmbeddedAuthWithSDKs) directory).

## Known issues

## Contributing
 
We are happy to accept contributions and PRs! Please see the [contribution guide](CONTRIBUTING.md) to understand how to structure a contribution.

[devforum]: https://devforum.okta.com/
[swiftdocs]: https://developer.okta.com/okta-idx-swift/latest/
[lang-landing]: https://developer.okta.com/code/swift/
[github-issues]: https://github.com/okta/okta-idx-swift/issues
[github-releases]: https://github.com/okta/okta-idx-swift/releases
[Rate Limiting at Okta]: https://developer.okta.com/docs/api/getting_started/rate-limits
[okta-library-versioning]: https://developer.okta.com/code/library-versions
