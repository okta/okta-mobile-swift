# Okta Identity Engine Library

**Table of Contents**

<!-- TOC depthFrom:2 depthTo:3 -->
<!-- /TOC -->

## Design Principles

This repository contains the Okta IDX SDK for Swift. This SDK can be used in your native client code (iOS, macOS) to assist in authenticating users against the Okta Identity Engine.

> :grey_exclamation: The use of this SDK requires you to be a part of our limited general availability (LGA) program with access to Okta Identity Engine. If you want to request to be a part of our LGA program for Okta Identity Engine, please reach out to your account manager. If you do not have an account manager, please reach out to oie@okta.com for more information.

> :warning: Beta alert! This library is in beta. See [release status](#release-status) for more information.

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
    
    client.introspect(context.interactionHandle) { (response, error) in
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
client.start { (response, error) in
    guard let response = response else {
        // Handle error
        return
    }
    
    // Use response
}
```

### Get new tokens using username & password

In this example the sign-on policy has no authenticators required.

> Note: Steps to identify the user might change based on your Org configuration.

```swift
client.start { (response, error) in
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

### Cancel the OIE transaction and start a new one

```swift
client.start { (response, error) in
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

#### Login using password, and enroll Security Question authenticator

In this example, the org is configured to require a security

> Note: In this example, it is assumed that the session has already been initiated, and the username and password have been submitted.  Please see the above section for more details.

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

In this example, the Org is configured to require an email as a second authenticator. After answering the password challenge, users have to select _email_ and enter the code to finish the process.

> Note: Steps to identify the user might change based on your Org configuration.

```swift
client.start { (response, error) in
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

> Note: Steps to identify the user might change based on your Org configuration.

> Note: This example assumes the identifier has been supplied, and the first authenticator challenge has already been performed.

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

client.start() { (response, error) in
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

## Supported Platforms

### iOS

### macOS

### tvOS _(Aspirational)_

## Install

### Swift Package Manager

Add the following to the `dependencies` attribute defined in your `Package.swift` file. You can select the version using the `majorVersion` and `minor` parameters. For example:

```swift
dependencies: [
    .Package(url: "https://github.com/okta/okta-idx-swift.git", majorVersion: <majorVersion>, minor: <minor>)
]
```

### Cocoapods

Simply add the following line to your `Podfile`:

```ruby
pod 'OktaIdx'
```

Then install it into your project:

```bash
pod install
```

### Carthage

To integrate this SDK into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your Cartfile:
```ruby
github "okta/okta-idx-swift"
```

## Usage Guide

## Configuration Reference

## API Reference

## Development

## Known issues
