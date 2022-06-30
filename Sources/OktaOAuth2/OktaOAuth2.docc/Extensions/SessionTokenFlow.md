# ``OktaOAuth2/SessionTokenFlow``

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

This flow is typically used in conjunction with the [classic Okta native authentication library](https://github.com/okta/okta-auth-swift). For native authentication using the Okta Identity Engine (OIE), please use the [Okta IDX library](https://github.com/okta/okta-idx-swift).

## Usage

When implementing OktaAuthNative, the `onStatusChange` argument is invoked for various state changes throughout authentication. Once the `.success` state is received, the returned status contains a session token which can be exchanged for full access tokens. Within that handler, you can use the ``SessionTokenFlow/start(with:context:)`` function to receive a token.

```swift
switch status.statusType {
case .success:
    guard let status = status as? OktaAuthStatusSuccess,
          let sessionToken = status.sessionToken
    else {
        // Handle this error condition
        return
    }
    
    let flow: SessionTokenFlow
    do {
        // Use the convenience initializer which reads
        // client configuration from `Okta.plist`.
        flow = try SessionTokenFlow()
    } catch {
        // Handle this error
        return
    }
    
    Task {
        do {
            let token = try await flow.start(with: sessionToken)
            try Credential.store(token)
        } catch {
            // Handle the error
        }
    }

default:
    // Handle other statuses
}
```
