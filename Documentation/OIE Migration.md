
# Okta OIE / IDX Migration Guide

## Migrating from `okta-auth-swift`

The OktaIdx SDK provides a dynamic approach to authenticating users, allowing server-side policy to dictate how a client application can progress through to signing in a user. For general usage patterns, please see the main README.md, which highlights many of the flows and patterns you can use to implement your app's authentication.

For specific suggestions on how to implement the various capabilities that `okta-auth-swift` provides, please see the following suggestions.

### Configuring and initializing your client

```swift
let config = IDXClient.Configuration(
    issuer: "https://{yourOktaDomain}/oauth2/default",
    clientId: "clientId",
    clientSecret: nil,
    scopes: ["openid", "email", "offline_access"],
    redirectUri: "com.myapp:/redirect/uri")
    
IDXClient.start(configuration: config) { result in
    switch result {
    case .failure(let error):
        // Handle the error
    case .success(let client):
        // Proceed to the next step
        client.resume() { result in
            // Handle the result
        }
    }
}
```

### Authenticate a user 

```swift
if let identify = response.remediations[.identify],
   let usernameField = identify["identifier"],
   let passwordField = identify["credentials.passcode"]
{
    usernameField.value = "user@example.com"
    passwordField.value = "secret"
    identify.proceed() { result in
        // Handle the result
    } 
}
```

### Forgot password

Password recovery is supported through the use of the current authenticator's associated actions.  This can be accessed through the use of the response's `authenticators` collection. Not all authenticators have the same set of capabilities, so these additional features are exposed through the use of protocols.  So those authenticators that can support account recovery, you can check to see if provides that capability

```swift
if let recoverable = response.authenticators.current?.recoverable {
    recoverable.recover { (response, error) in
        // Handle the response
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

### Verify recovery token

After recovery has begun, a token or one-time code will be sent out-of-band to the user. The response to the recovery request in the previous section will enable a user to supply the code to the `challengeAuthenticator` remediation.

```swift
guard let remediation = response.remediations[.challengeAuthenticator],
      let passcodeField = remediation["credentials.passcode"]
else {
    // Handle error
    return
}

passcodeField.value = recoveryToken
remediation.proceed { (response, error) in
    // Handle response
}
```

### Working with Authenticators / Factors

Authenticators (aka Factors from the okta-auth-swift SDK) are selected, authenticated, and enrolled in a policy-driven fashion, in response to results returned from the server. As such, specific remediation types are returned when these options are available to the user.

#### `selectAuthenticatorAuthenticate`

This remediation is returned when a user has the option to select an authenticator to use to authenticate during log in. The list of available authenticators are returned as options to the `authenticator` field.

```swift
if let remediation = response.remediations[.selectAuthenticatorAuthenticate],
   let authenticatorField = remediation["authenticator"],
   let authenticatorOptions = authenticatorField.options
{
    for option in authenticatorOptions {
        let label = option.label // This property is a user-visible label representing the choice (e.g. Email/Phone)
        
        // Display choices to the user
    }
}
```

To select an option, the desired option can be assigned to the `selectedOption` property of the authenticator field, after which you can call `remediation.proceed()` to make the selection.

```swift
authenticatorField.selectedOption = option
remediation.proceed { result in
    // Handle the response to enroll in the authenticator
}
```

#### `selectAuthenticatorEnroll`

Similar to `selectAuthenticatorAuthenticate`, this remediation allows a user to select a type of authenticator to enroll in. The approach is largely the same as selecting one to authenticate.

#### `challengeAuthenticator`

Once an authenticator has been selected, the user may be prompted to answer an authenticator challenge.  The fields returned in the remediation's form indicates whether or not an OTP token should be supplied, or other data that may be selected by the user.
