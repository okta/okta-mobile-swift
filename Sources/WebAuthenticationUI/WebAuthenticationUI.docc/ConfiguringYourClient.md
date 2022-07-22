# Configuring Your Client

Configure your WebAuthentication client to connect to your OAuth2 application.

## Overview

Signing users into your application requires an OAuth2 client to be configured within Okta, which provides credentials and other information used by your application to connect and sign users in.

There are a variety of ways you may set your client up, which depends on your development process or preferences.

## Utilize an Okta.plist file

By far the simplest approach is to create a property-list file within your application named `Okta.plist`. This is the filename used when calling the default initializer, and makes your code very straightforward when authenticating.

The keys read from this property list file are:

 Key | Required | Description |
---|---|---
`issuer` | ✔ | Issuer URL for the client.
`clientId` | ✔ | Client ID for the Okta application.
`scopes` | ✔ | Scopes the client is requesting.
`redirectUri` | ✔  | Redirect URI for the Okta application.
`logoutRedirectUri` | | Logout URI used for the Okta application.
Other... | | Any additional keys will be passed to the `additionalParameters` argument of the initializer.

Once this file is created, your application can use the default initializer:

```swift
@IBAction func signIn(_ sender: Any) {
    let auth = try WebAuthentication()
    auth.signIn(from: view.window) { result in
        // Handle the response
    }
}
```

Alternatively, the ``WebAuthentication/shared`` property implicitly will do this for you.

```swift
@IBAction func signIn(_ sender: Any) {
    WebAuthentication.shared.signIn(from: view.window) { result in
        // Handle the response
    }
}
```

## Use a custom property list

There may be circumstances where your application connects to multiple client configurations, particularly during development. In this case, you can create a custom property list file that follows the same keys described in the previous section, and you can construct your authentication session using the ``WebAuthentication/init(plist:)`` initializer.

```swift
@IBAction func signIn(_ sender: Any) {
    guard let fileURL = Bundle.main.url(
        forResource: "Client",
        withExtension: "plist")
    else {
        return
    }

    let auth = try WebAuthentication(plist: fileURL)
    auth.signIn(from: view.window) { result in
        // Handle the response
    }
}
```

## Assign values at runtime

Another approach can be to use an initializer that passes those configuration values at runtime, as opposed to constructing a static property list.  The initializer accepts all the same 

```swift
@IBAction func signIn(_ sender: Any) {
    let auth = WebAuthentication(
        issuer: URL(string: "https://my-app.okta.com")!,
        clientId: "my-client-id",
        scopes: "openid offline_access profile",
        redirectUri: URL(string: "com.my.app:/callback")!)

    auth.signIn(from: view.window) { result in
        // Handle the response
    }
}
```

> Note: You'll note in this example we don't have to use the `try` keyword when initializing the session. This is because the previous property list-based approaches could fail when reading the file. 

## Singleton Access

The ``WebAuthentication/shared`` singleton provides convenient access to your client's authentication instance. By default this value will use the `Okta.plist` file to configure the client, if one is available.

If your application constructs a ``WebAuthentication`` client using a custom property list, or through one of the other initializers, the ``WebAuthentication/shared`` property will retain that value for you.

For example:

```swift
func application(_ application: UIApplication, 
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
{
    let _ = WebAuthentication(issuer: issuerUrl,
                              clientId: "my-client-id",
                              scopes: "openid offline_access profile",
                              redirectUri: redirectUri)
    return true
}

// In another part of your application
@IBAction func signIn(_ sender: Any) {
    WebAuthentication.shared?.signIn(from: view.window) { result in
        // Handle the response
    }
}
```

## Supply a custom URLSession

If you need to have control over the URLSession instance that is used when authenticating a user, you can construct an `OktaOAuth2` `AuthorizationCodeFlow.Configuration` object and supply the custom session to the initializer.

```swift
import OktaOAuth2

let config = AuthorizationCodeFlow.Configuration(
    issuer: issuer,
    clientId: clientId,
    scopes: scopes,
    redirectUri: redirectUri)
let auth = WebAuthentication(configuration: config,
                             session: myURLSession)
```

## Utilize a pre-configured OAuth2Client / use a pre-configured context

If your application interacts with other OAuth2 API endpoints, and you want to use the same client instance for your browser-based sign in, you can construct your own `AuthorizationCodeFlow` instance to supply it to the initializer.

Alternatively, if you have an authorization code flow context from a previous authentication session, and you want to resume authenticating from that point (e.g. your user is signing in, and the application is closed unexpectedly during that process). This context can be supplied to the flow and can be resumed.

```swift
import OktaOAuth2

let flow = AuthorizationCodeFlow(clientConfig,
                                 client: oauth2Client)
let auth = WebAuthentication(flow: flow,
                          context: flowContext)
auth.signIn(from: view.window) { result in
    // Handle the response
}
```
