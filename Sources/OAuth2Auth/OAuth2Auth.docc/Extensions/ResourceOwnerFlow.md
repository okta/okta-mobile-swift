# ``OAuth2Auth/ResourceOwnerFlow``

## Usage

As an example, we'll use Swift Concurrency, since these asynchronous methods can be used inline easily.

```swift
let client = OAuth2Client(baseURL: URL(string: "https://example.okta.com")!,
                          clientId: "abc123client",
                          scopes: "openid offline_access email profile")
let flow = client.resourceOwnerFlow()

// Authenticate with a username and password.
let token = try await flow.start(username: "smeagol", password: "myprecious")
```

Alternatively, an instance of ``ResourceOwnerFlow`` can be created using one of its initializers. The following example uses the ``ResourceOwnerFlow/init(issuerURL:clientId:scope:additionalParameters:)`` initializer.

```swift
let flow = ResourceOwnerFlow(issuerURL: URL(string: "https://example.okta.com")!,
                             clientId: "abc123client",
                             scope: "openid offline_access email profile")
let token = try await flow.start(username: "smeagol", password: "myprecious")
```

Finally, if you already have an `OAuth2Client` instance available, you can supply that to the ``ResourceOwnerFlow/init(client:additionalParameters:)`` initializer.

```swift
let client = OAuth2Client(issuerURL: URL(string: "https://example.okta.com")!,
                          clientId: "abc123client",
                          scope: "openid offline_access email profile")
let flow = ResourceOwnerFlow(client: client)
let token = try await flow.start(username: "smeagol", password: "myprecious")
```
