# ``OAuth2Auth/TokenExchangeFlow``

The Token Exchange Flow allows a client to get the Access Token exchanging other tokens. 

As an example, consider [SSO for Native Apps](https://developer.okta.com/docs/guides/configure-native-sso/main/#native-sso-flow) where a client exchanges the ID and the Device Secret tokens to get the access to the resource.

You can create an instance of  ``TokenExchangeFlow`` either through the `resourceOwnerFlow()` method on `OAuth2Client`, or you can use any of the designated initializers to construct the flow.

As an example, we'll use Swift Concurrency, since these asynchronous methods can be used inline easily, though ``TokenExchangeFlow`` can just as easily be used with completion blocks or through the use of the `AuthenticationDelegate`.

```swift
let flow = TokenExchangeFlow(
    issuerURL: URL(string: "https://example.okta.com")!,
    clientId: "abc123client",
    scope: "openid offline_access email profile",
    audience: .default)

let tokens: [TokenType] = [
    .actor(type: .deviceSecret, value: "DeviceToken"),
    .subject(type: .idToken, value: "IDToken")
]
let token = try await flow.start(with: tokens)
```
