# ``OktaDirectAuth/DirectAuthenticationFlow``

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

## Usage

You can create an instance of ``DirectAuthenticationFlow`` with your client settings, or you can use one of several convenience initializers to simplify the process.

```swift
let flow = DirectAuthenticationFlow(
    issuer: URL(string: "https://example.okta.com")!,
    clientId: "abc123client",
    scopes: "openid offline_access email profile")

// Start authentication with a user's chosen factor.
let status = try await flow.start("jane.doe@example.com",
                            with: .password("SuperSecret"))
switch status {
case .success(let token):
    // Sign in successful with 1FA, so store the token.
    try Credential.store(token)
case .mfaRequired(_):
    // MFA required, so challenge the user.
    switch try await flow.resume(status, with: .otp(code: 123456)) {
    case .success(let token):
        // Sign in successful with 2FA, so store the token.
        try Credential.store(token)
    case .mfaRequired(_):
        // Continue MFA.
    }
}
```

> Note: The above example uses Swift Concurrency, since these asynchronous methods can be used inline easily. However block-based functions are available for all asynchronous operations.

## Handling the authentication workflow

Authentication factors are separated into two groups:
* ``PrimaryFactor`` -- Used for initial authentication when calling ``start(_:with:)`` (or ``start(_:with:completion:)`` when using blocks)
* ``SecondaryFactor`` -- Used for supplying additional MFA factors, with the ``resume(_:with:)`` function (or ``resume(_:with:completion:)`` when using blocks)

Each of the fuctions using these factors returns an instance of ``Status``, which indicates whether or not authentication is successful, or if multiple factors are required.

![Flowchart describing the Direct Authentication workflow.](DirectAuthFlowChart)

## Topics

### Creating a flow

- ``DirectAuthenticationFlow/init()``
- ``DirectAuthenticationFlow/init(plist:)``
- ``DirectAuthenticationFlow/init(issuer:clientId:scopes:supportedGrants:)``
- ``DirectAuthenticationFlow/init(supportedGrants:client:)``

### Starting MFA or signing in with 1FA

- ``DirectAuthenticationFlow/start(_:with:)``
- ``DirectAuthenticationFlow/start(_:with:completion:)``
- ``DirectAuthenticationFlow/PrimaryFactor``
- ``DirectAuthenticationFlow/OOBChannel``

### Continuing sign in with MFA

- ``DirectAuthenticationFlow/resume(_:with:)``
- ``DirectAuthenticationFlow/resume(_:with:completion:)``
- ``DirectAuthenticationFlow/SecondaryFactor``
- ``DirectAuthenticationFlow/OOBChannel``

### Sign in responses

- ``DirectAuthenticationFlow/Status``
- ``DirectAuthenticationFlow/MFAContext``

### Flow configuration values

- ``DirectAuthenticationFlow/client``
- ``DirectAuthenticationFlow/supportedGrantTypes``

### Responding to changes

- ``DirectAuthenticationFlow/delegateCollection``
- ``DirectAuthenticationFlow/isAuthenticating``

### Resetting a flow

- ``DirectAuthenticationFlow/reset()``
