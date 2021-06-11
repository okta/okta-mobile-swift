[<img src="https://aws1.discourse-cdn.com/standard14/uploads/oktadev/original/1X/0c6402653dfb70edc661d4976a43a46f33e5e919.png" align="right" width="256px"/>](https://devforum.okta.com/)

[![Support](https://img.shields.io/badge/support-Developer%20Forum-blue.svg)][devforum]
[![API Reference](https://img.shields.io/badge/docs-reference-lightgrey.svg)][swiftdocs]

# Okta IDX Swift SDK

> :grey_exclamation: The use of this SDK requires usage of the Okta Identity Engine. This functionality is in general availability but is being gradually rolled out to customers. If you want to request to gain access to the Okta Identity Engine, please reach out to your account manager. If you do not have an account manager, please reach out to oie@okta.com for more information.

> :warning: Beta alert! This library is in beta. See [release status](#release-status) for more information.

This library is built for projects written in Swift to communicate with Okta as an OAuth 2.0 + OpenID Connect provider. It works with [Okta's Identity Engine](https://developer.okta.com/docs/concepts/ie-intro/) to authenticate and register users.

To see this library working in a sample, check out our [iOS Sample Application](Samples/EmbeddedAuthWithSDKs)

**Table of Contents**

<!-- TOC depthFrom:2 depthTo:3 -->
<!-- /TOC -->

## Release status

This library uses semantic versioning and follows Okta's [Library Version Policy][okta-library-versioning].

| Version | Status                             |
| ------- | ---------------------------------- |
| 0.1.0   | :warning: Beta                     |

The latest release can always be found on the [releases page][github-releases].

## Need help?
 
If you run into problems using the SDK, you can
 
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

## Usage

The below code snippets will help you understand how to use this library.

Once you initialize an `IDXClient`, you can call methods to make requests to the Okta IDX API. Please see the [configuration reference](#configuration-reference) section for more details.

### Create the client configuration

```swift
let config = IDXClient.Configuration(
    issuer: "<#issuer#>", // e.g. https://foo.okta.com/oauth2/default, https://foo.okta.com/oauth2/ausar5vgt5TSDsfcJ0h7
    clientId: "<#clientId#>",
    clientSecret: nil, // Optional, only required for confidential clients.
    scopes: ["openid", "email", "offline_access", "<#otherScopes#>"],
    redirectUri: "<#redirectUri#>") // Must match the redirect uri in client app settings/console
```

### Create the Client

```swift
IDXClient.start(with: configuration) { (client, error) in
    guard let client = client else {
        // Handle the error
        return
    }
}
```

### Start / continue the authentication session

```swift
client.resume { (response, error) in
    guard let response = response else {
        // Handle error
        return
    }
    
    // Use response
}
```

### Get new tokens using username & password

In this example the sign-on policy has no authenticators required.

> **Note:** Steps to identify the user might change based on your Org configuration.

```swift
func signIn(username: String, password: String, completion: @escaping(IDXClient.Token?, Error?) -> Void) {
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

### Email verification polling

When using an email authenticator, the user will receive both a numeric code and a link to verify their identity. If the user clicks this link, it will verify the authenticator and the application can immediately proceed to the next remediation step.

*Note:* This code assumes that it is running in the same UI where the user is asked for their verification code.

```swift
guard let remediation = response.remediations[.challengeAuthenticator],
      let authenticator = remediation.authenticators[.email] as? IDXClient.Authenticator.Email
else {
    // Handle error
    return
}

if authenticator.canPoll {
    authenticator.startPolling { (response, error) in
        guard let response = response else {
            // Handle error
            return
        }
        
        // Use the response to display the UI for the next step
        // in the user's authentication
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
    // Do something with the form fie.d
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
    var remediation: IDXClient.Remediation
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
