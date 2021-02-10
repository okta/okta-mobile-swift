[<img src="https://aws1.discourse-cdn.com/standard14/uploads/oktadev/original/1X/0c6402653dfb70edc661d4976a43a46f33e5e919.png" align="right" width="256px"/>](https://devforum.okta.com/)

[![Support](https://img.shields.io/badge/support-Developer%20Forum-blue.svg)][devforum]
[![API Reference](https://img.shields.io/badge/docs-reference-lightgrey.svg)][swiftdocs]

# Okta Swift IDX SDK

This repository contains the Okta IDX SDK for Swift. This SDK can be used in your native client code (iOS, macOS) to assist in authenticating users against the Okta Identity Engine.

> :grey_exclamation: The use of this SDK requires you to be a part of our limited general availability (LGA) program with access to Okta Identity Engine. If you want to request to be a part of our LGA program for Okta Identity Engine, please reach out to your account manager. If you do not have an account manager, please reach out to oie@okta.com for more information.

> :warning: Beta alert! This library is in beta. See [release status](#release-status) for more information.

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

## Getting Started

### Prerequisites

You will need:

* An Okta account, called an _organization_ (sign up for a free [developer organization](https://developer.okta.com/signup) if you need one).

### Supported Platforms

#### iOS

OktaIdx supports iOS 10 and above.

### Install

#### Swift Package Manager

Add the following to the `dependencies` attribute defined in your `Package.swift` file. You can select the version using the `majorVersion` and `minor` parameters. For example:

```swift
dependencies: [
    .Package(url: "https://github.com/okta/okta-idx-swift.git", majorVersion: <majorVersion>, minor: <minor>)
]
```

#### Cocoapods

Simply add the following line to your `Podfile`:

```ruby
pod 'OktaIdx'
```

Then install it into your project:

```bash
pod install
```

#### Carthage

To integrate this SDK into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your Cartfile:
```ruby
github "okta/okta-idx-swift"
```

## Usage guide

The below code snippets will help you understand how to use this library. For more a more detailed introduction, you can also see the companion Xcode Playground.

Once you initialize an `IDXClient`, you can call methods to make requests to the Okta API. Please see the [configuration reference](#configuration-reference) section for more details.

### Create the Client

```swift
let config = IDXClient.Configuration(issuer: "<#issuer#>", // e.g. https://foo.okta.com/oauth2/default, https://foo.okta.com/oauth2/ausar5vgt5TSDsfcJ0h7
                                     clientId: "<#clientId#>",
                                     clientSecret: nil, // Optional, only required for confidential clients.
                                     scopes: ["openid", "email", "offline_access", "<#otherScopes#>"],
                                     redirectUri: "<#redirectUri#>" // // Must match the redirect uri in client app settings/console)
let client = IDXClient(configuration: config)
```

### Start the authentication session

```swift
client.interact { (context, error) in
    guard let context = context else {
        // Handle error
        return
    }
    
    client.introspect(context) { (response, error) in
        guard let response = response else {
            // Handle error
            return
        }
        
        // Use response
    }
}
```

For convenience, when direct access to the `interact` and `introspect` methods aren't necessary, a `start` method is provided that encapsulates the two previous calls.

```swift
client.start { (context, response, error) in
    guard let context = context,
          let response = response else
    {
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
// Use the client created above
client.start { (context, response, error) in
    guard let identifyOption = response?.remediation?[.identify],
          let identifierField = identifyOption["identifier"] else
    {
        // Handle error
        return
    }
    
    var params = IDXClient.Remediation.Parameters()
    params[identifierField] = "<#username#>"

    remediation.proceed(using: params) { (response, error) in
        guard let authenticatorOption = response?.remediation?[.challengeAuthenticator],
              let passcodeField = authenticatorOption["credentials"]?["passcode"] else
        {
            // Handle error
            return
        }

        let params = IDXClient.Remediation.Parameters()
        params[passcodeField] = "<#password#>"
        remediation.proceed(using: params) { (response, error) in
            guard let response = response else {
                // Handle error
                return
            }
            
            guard response.isLoginSuccessful else {
                // Handle error
                return
            }

            response.exchangeCode(with: context) { (token, error) in
                guard let token = token else {
                    // Handle error
                    return
                }
                
                print("""
                Exchanged interaction code for token:
                    accessToken:  \(token.accessToken)
                    refreshToken: \(token.refreshToken ?? "Unavailable")
                    idToken:      \(token.idToken ?? "Unavailable")
                    tokenType:    \(token.tokenType)
                    scope:        \(token.scope)
                    expiresIn:    \(token.expiresIn) seconds
                """)
            }
        }
    }
}
```

### Cancel the OIE transaction and start a new one

```swift
client.start { (_, response, error) in
    guard let identifyOption = response?.remediation?[.identify],
          let identifierField = identifyOption["identifier"] else
    {
        // Handle error
        return
    }

    var params = IDXClient.Remediation.Parameters()
    params[identifierField] = "<#username#>"

    remediation.proceed(using: params) { (response, error) in
        guard let response = response else {
            // Handle error
            return
        }

        // Cancel the current response, and begin fresh
        response.cancel() { (response, error) in
            guard let response = response else {
                // Handle error
                return
            }

            // Continue the remediation flow ... 
        }
    }
}
```

### Remediation/MFA scenarios with sign-on policy

#### Login using password, and enroll a Security Question authenticator

In this example, the org is configured to require a security question as a second authenticator. After answering the password challenge, users have to select *security question*, select a question, and enter an answer to finish the process.

> **Note:** In this example, it is assumed that the session has already been initiated, and the username and password have been submitted.  Please see the above section for more details.
>
> Additionally, this org is configured to allow additional optional authenticators, which is being skipped in this example.

```swift
guard let response = response,
      let authenticatorOption = response.remediation?[.selectAuthenticatorEnroll],
      let authenticatorField = authenticatorOption["authenticator"],
      let questionOption = authenticatorField.options?.filter({ option in
          option.label == "Security Question"
      }).first else
{
    // Handle error
    return
}

authenticatorOption.proceed(using: .init([authenticatorField: questionOption])) { (response, error) in
    guard let response = response,
          let enrollOption = response.remediation?["enroll-authenticator"],
          let credentials = enrollOption["credentials"],
          let questionOption = credentials.options?.filter({ option in
              option.label == "Create my own security question"
          }).first,
          let questionField = questionOption["question"],
          let answerField = questionOption["answer"] else
    {
        // Handle error
        return
    }
    
    let params = IDXClient.Remediation.Parameters()
    params[credentials] = questionOption
    params[questionField] = "What is my favorite CIAM service?"
    params[answerField] = "Okta"
    
    enrollOption.proceed(using: params) { (response, error) in
        guard let skipOption = response?.remediation?["skip"] else {
            // Handle error
            return
        }
        
        // Skip other optional factors if applicable
        skipOption.proceed() { (response, error) in
            guard let response = response else {
                // Handle error
                return
            }
            guard response.isLoginSuccessful else {
                // Handle error
                return
            }
            
            // Using the `context` value stored in the IDXClient, so the value is being omitted here.
            response.exchangeCode { (token, error) in
                guard let token = token else {
                    // Handle error
                    return
                }
                
                print("""
                Exchanged interaction code for token:
                    accessToken:  \(token.accessToken)
                    refreshToken: \(token.refreshToken ?? "Unavailable")
                    idToken:      \(token.idToken ?? "Unavailable")
                    tokenType:    \(token.tokenType)
                    scope:        \(token.scope)
                    expiresIn:    \(token.expiresIn) seconds
                """)
            }
        }
    }
}
```

#### Login using password and email authenticator

In this example, the Org is configured to require an email as a second authenticator. After answering the password challenge, users have to select *email* and enter the code to finish the process.

> **Note:** Steps to identify the user might change based on your Org configuration.

```swift
client.start { (_, response, error) in
    guard let identifyOption = response?.remediation?[.identify],
          let identifierField = identifyOption["identifier"] else
    {
        // Handle error
        return
    }
    
    remediation.proceed(using: .init([identifierField: "<#username#>") { (response, error) in
        guard let response = response,
              let authenticatorOption = response.remediation?[.selectAuthenticatorAuthenticate],
              let authenticatorField = authenticatorOption["authenticator"],
              let passwordOption = authenticatorField.options?.filter({ option in
                  option.label == "Password"
              }).first else
        {
            // Handle error
            return
        }

        // Select the password authenticator option
        authenticatorOption.proceed(using: .init([authenticatorField: passwordOption]))
            guard let authenticatorOption = response?.remediation?[.challengeAuthenticator],
                  let passcodeField = authenticatorOption["credentials"]?["passcode"] else
            {
                // Handle error
                return
            }

            remediation.proceed(using: .init([passcodeField: "<#password#>"])) { (response, error) in
                guard let response = response,
                      let authenticatorOption = response.remediation?[.selectAuthenticatorAuthenticate],
                      let authenticatorField = authenticatorOption["authenticator"],
                      let emailOption = authenticatorField.options?.filter({ option in
                          option.label == "Email"
                      }).first else
                {
                    // Handle error
                    return
                }
                
                authenticatorOption.proceed(using: .init([authenticatorField: emailOption])) { (response, error) in
                    guard let authenticatorOption = response?.remediation?[.challengeAuthenticator],
                          let passcodeField = authenticatorOption["credentials"]?["passcode"] else
                    {
                        // Handle error
                        return
                    }

                    // Proceed to the email challenge
                    remediation.proceed(using: .init([passcodeField: "<#email code#>"])) { (response, error) in
                        guard let response = response else {
                            // Handle error
                            return
                        }
                        guard response.isLoginSuccessful else {
                            // Handle error
                            return
                        }
                        
                        response.exchangeCode { (token, error) in
                            guard let token = token else {
                                // Handle error
                                return
                            }
                            
                            print("""
                            Exchanged interaction code for token:
                                accessToken:  \(token.accessToken)
                                refreshToken: \(token.refreshToken ?? "Unavailable")
                                idToken:      \(token.idToken ?? "Unavailable")
                                tokenType:    \(token.tokenType)
                                scope:        \(token.scope)
                                expiresIn:    \(token.expiresIn) seconds
                            """)
                        }
                    }
                }    
            }
        }
    }
}
```

#### Login using password, and enroll a phone authenticator (SMS/Voice)

In this example, the Org is configured with phone as a second authenticator. After answering the password challenge, users have to provide a phone number and then enter a code to finish the process.

> **Note:** Steps to identify the user might change based on your Org configuration.

> **Note:** This example assumes the identifier has been supplied, and the first authenticator challenge has already been performed.

```swift
guard let response = response,
      let authenticatorOption = response.remediation?[.selectAuthenticatorEnroll],
      let authenticatorField = authenticatorOption["authenticator"],
      let phoneOption = authenticatorField.options?.filter({ option in
          option.label == "Phone"
      }).first,
      let phoneNumberField = phoneOption["phoneNumber"],
      let methodTypeField = phoneOption["methodType"],
      let smsMethod = methodTypeField.options?.filter({ option in
          option.label == "SMS"
      }) else
{
    // Handle error
    return
}

var params = IDXClient.Remediation.Parameters()
params[phoneNumberField] = "+15551234567"
params[methodTypeField] = smsMethod

authenticatorOption.proceed(using: params) { (response, error) in
    guard let response = response,
          let enrollOption = response.remediation?["enroll-authenticator"],
          let credentials = enrollOption["credentials"],
          let codeField = credentials.options?.filter({ option in
              option.label == "Create my own security question"
          }).first,
          let questionField = questionOption["question"],
          let answerField = questionOption["answer"] else
    {
        // Handle error
        return
    }
    
    guard let authenticatorOption = response?.remediation?[.challengeAuthenticator],
          let passcodeField = authenticatorOption["credentials"]?["passcode"] else
    {
        // Handle error
        return
    }

    // Proceed to the SMS code challenge
    remediation.proceed(using: .init([passcodeField: "<#sms code#>"])) { (response, error) in
        guard let response = response else {
            // Handle error
            return
        }
        guard response.isLoginSuccessful else {
            // Handle error
            return
        }
        
        response.exchangeCode { (token, error) in
            guard let token = token else {
                // Handle error
                return
            }
            
            print("""
            Exchanged interaction code for token:
                accessToken:  \(token.accessToken)
                refreshToken: \(token.refreshToken ?? "Unavailable")
                idToken:      \(token.idToken ?? "Unavailable")
                tokenType:    \(token.tokenType)
                scope:        \(token.scope)
                expiresIn:    \(token.expiresIn) seconds
            """)
        }
    }
}    
```

### Email verification polling

```swift
func poll(response: IDXClient.Response,
          completion: @escaping(IDXClient.Response?, Error?) -> Void)
{
    guard let poll = response.currentAuthenticatorEnrollment?.poll,
          let refreshTime = poll.refresh else
    {
        completion(response, nil)
        return
    }
    
    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + refreshTime) {
        poll.proceed { (response, error) in
            guard let response = response else {
                completion(nil, error)
                return
            }
            
            self.poll(response: response, completion: completion)
        }
    }
}

client.start() { (_, response, error) in
    guard let identify = response?.remediation?[.identify],
          let identifierField = identify["identifier"] else
    {
        // Handle error
        return
    }
    
    identify.proceed(with: .init([identifierField: "<#username#>"])) { (response, error) in
        guard let selectAuthenticator = response?.remediation?[.selectAuthenticatorAuthenticate],
              let authenticatorField = selectAuthenticator["authenticator"],
              let passcodeOption = authenticatorField.options?.filter({ $0.label == "Password" }).first else
        {
            // Handle error
            return
        }
        
        selectAuthenticator.proceed(with: .init([authenticatorField: passcodeOption])) { (response, error) in
            guard let passcodeChallenge = response?.remediation?[.challengeAuthenticator],
                  let passcodeField = passcodeChallenge["credentials"]?["passcode"] else
            {
                // Handle error
                return
            }
            
            passcodeChallenge.proceed(with: .init([passcodeField: "<#password#>"])) { (response, error) in
                if let selectEmail = response?.remediation?[.selectAuthenticatorAuthenticate],
                   let authenticatorField = selectEmail["authenticator"],
                   let emailOption = authenticatorField.options?.filter({ $0.label == "Email" }).first
                {
                    selectEmail.proceed(with: .init([authenticatorField: emailOption])) { (response, error) in
                        guard let response = response else {
                            // Handle error
                            return
                        }
                        self.poll(response: response) { (response, error) in
                            guard let response = response else {
                                // Handle error
                                return
                            }

                            guard response.isLoginSuccessful else {
                                // Handle error
                                return
                            }

                            response.exchangeCode { (token, error) in
                                guard let token = token else {
                                    // Handle error
                                    return
                                }
                                
                                // Use the token
                            }
                        }
                    }
                }
            }
        }
    }
}
```

### Check remediation options

Responses may contain multiple remediation options. There are multiple ways to identify which options are available.

```swift
// Select the option by its name using subscripting.
let option = response.remediation?["challenge-authenticator"]

// Select the option by its enum type using subscripting.
let option = response.remediation?[.challengeAuthenticator]

// Select the option by iterating over the array of options
let option = response.remediation?.remediationOptions.filter { $0.name == "challenge-authenticator" }.first
```

From this point, you can access the form values associated with it.

```swift
option.form?.forEach { formValue in
    // Do something with the form value
}
```

### Supplying values to remediation options

The purpose of using remediation options is to enable a user to make selections and supply user-data in response to these requests. These forms sometimes involve nested structures of values that require the data to be structured in a specific way. To this end, this SDK provides two primary ways to supply data and user selections to remediation options:

1. Using key/value dictionary values, which may potentially contain nested data;
2. Using the `IDXClient.Remediation.Parameters` object to store responses associated with their `FormValue`.

#### Using key/value dictionaries

When using this approach, you must be careful to ensure that all required values are populated, and in the correct structure.

```swift
// Simple shallow structure
option.proceed(with: ["identifier": "<#username#>"]) { (response, error) in
    // Handle the response
}

// Nested structure
option.proceed(with: ["challenge": ["passcode": "<#password#>"]]) { (response, error) in
    // Handle the response
}
```

For convenience, any read-only form values that are pre-populated with a value (for example, the `stateHandle` value) will automatically be merged and sent along with the data supplied through this API.

> **Note:** The automatic merging of read-only form data does not work when user-supplied data is sent along with nested optional form values. For these more complicated scenarios, the next approach is recommended.

#### Using the `Parameters` object

When submitting data to remediation options using the `Parameters` object, you don't need to be concerned about the nesting of values. Instead, user-supplied data is associated with the `FormValue` as the key.

```swift
// Simple shallow structure
let params = IDXClient.Remediation.Parameters()

guard let field = option["identifier"] else { return }
params[field] = "<#username#>"

option.proceed(with: params) { (response, error) in
    // Handle the response
}

// Nested structure
let params = IDXClient.Remediation.Parameters()

guard let field = option["challenge"]?["passcode"] else { return }
params[field] = "<#password#>"

option.proceed(with: params) { (response, error) in
    // Handle the response
}

// Using the initializer inline
guard let field = option["identifier"] else { return }
option.proceed(with: .init([field: "<#username#>"])) { (response, error) in
    // Handle the response
}
```

The `Parameters` object can be a convenient placeholder for user-supplied data while they populate their information into forms. Once all selections have been made, the object 

```swift
import SwiftUI

struct UsernameView: View {
    @State var username: String = ""
    let parameters = IDXClient.Remediation.Parameters()
    var remediationOption: IDXClient.Remediation.Option
    var body: some View {
        Form {
            TextField("Username", text: $username, onCommit: {
                guard let field = self.remediationOption["identifier"] else { return }
                parameters[field] = self.username
            })
            Button("Continue") {
                remediationOption.proceed(with: self.parameters)
            }
        }
    }
}
```

### Check remediation options and select an authenticator

Many times a user may have choices that they can select. For example, they may choose which type of authenticator they wish to authenticate or enroll with, or they may select a sub-option (such as "SMS" vs "Voice" when using a "Phone" authenticator).

When using the `Parameters` object, this selection can be made by assigning the chosen option to the enclosing form value.

```swift
let params = IDXClient.Remediation.Parameters()

if let remediationOption = response.remediation?[.selectAuthenticatorAuthenticate],
   let authenticatorField = remediationOption["authenticator"],
   let emailOption = authenticatorField.options?.filter({ $0.label == "Email" }).first
{
    remediationOption.proceed(with: .init([authenticatorField: emailOption])) { (response, error) in
        // Handle the response
    }
}
```

When combining options with nested sub-options, the same approach as above can be used, which is convenient especially when mixing option selections with user-supplied data. In the following example, the user is selecting the Phone authenticator, is then selecting the `SMS` authenticator method, and is supplying the phone number to send the SMS code to.

```swift
guard let authenticatorOption = response.remediation?[.selectAuthenticatorEnroll],
      let authenticatorField = authenticatorOption["authenticator"],
      let phoneOption = authenticatorField.options?.filter({ option in
          option.label == "Phone"
      }).first,
      let phoneNumberField = phoneOption["phoneNumber"],
      let methodTypeField = phoneOption["methodType"],
      let smsMethod = methodTypeField.options?.filter({ option in
          option.label == "SMS"
      }) else
{
    return
}

var params = IDXClient.Remediation.Parameters()
params[phoneNumberField] = "+15551234567"
params[methodTypeField] = smsMethod

authenticatorOption.proceed(using: params) { (response, error) in
    // Handle the response
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

To perform an end-to-end test, copy the `TestCredentials.xcconfig.example` file to `TestCredentials.xcconfig`, and update its contents to match your configuration as specified in the [prerequisites](#prerequisites). Next, you can run the test targets for both `okta-idx-ios` and `OktaIdxExample`.

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
