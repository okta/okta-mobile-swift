# ``OktaOAuth2/SessionTokenFlow``

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

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
