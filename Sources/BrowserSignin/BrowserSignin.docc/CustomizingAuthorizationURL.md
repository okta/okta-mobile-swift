# Customizing the Authorization URL

Features and APIs to enable customization of the authorization URL.

## Overview

Many times the URL presented to the user within a browser may need to be customized. For example, a custom query string argument needs to be appended to the URL, such as `idp`, `login_hint`, or other parameters. These may be used by the Sign In Widget to determine how to present the UI to your user. Alternatively, other advanced use-cases may require more complex configuration of the URL.

Since this URL is typically generated at runtime, APIs are needed to give you the capability to configure this URL.

## signIn and signOut Options

The simplest approach to customizing your authorization URL is by specifying options when invoking the ``BrowserSignin/BrowserSignin/signIn(from:context:)`` or ``BrowserSignin/BrowserSignin/signOut(from:token:context:)`` functions.

```swift
let auth = BrowserSignin(issuerURL: issuer,
                         clientId: clientId,
                         scope: "openid profile offline_access",
                         redirectUri: redirectUri,
                         logoutRedirectUri: logoutRedirectUri)

var context = AuthoriationCodeFlow.Context()
context.loginHint = "user@example.com"
context.prompt = .login

let token = try await auth.signIn(from: view.window,
                                  context: context)
```

## Query String Parameters

Another approach to customizing your authorization URL is through adding additional parameters to the query string. These values can be supplied to the initializer through the ``BrowserSignin/BrowserSignin/init(issuerURL:clientId:scope:redirectUri:logoutRedirectUri:additionalParameters:)`` initializer or through the `Okta.plist` configuration format (see <doc:ConfiguringYourClient> for more information), or through the optional context objects supplied to the `signIn` or `signOut` functions.

When passing values to the initializer, you can supply raw string key/value pairs.

```swift
let auth = BrowserSignin(issuerURL: issuer,
                         clientId: clientId,
                         scope: "openid profile offline_access",
                         redirectUri: redirectUri,
                         additionalParameters: [ "idp": myIdpString ])
let token = try await auth.signIn()
```

## Customizing the Authorization URL through Delegation

The ``BrowserSignin/BrowserSignin`` class exposes the underlying OAuth2 flow through the ``BrowserSignin/BrowserSignin/signInFlow`` property. The authentication flows, defined within the OAuth2Auth SDK, all support a multicast delegate mechanism to notify other parts of the SDK as well as your application of important events.

If your code conforms to the `AuthorizationCodeFlowDelegate` protocol, and implements the `authentication(flow:customizeUrl:)` method, you can alter the URL before it is loaded in the browser.

```swift
let auth = try BrowserSignin()
auth.signInFlow.add(delegate: self)

let token = try await auth.signIn()
```

Elsewhere in your code, in the class that conforms to `AuthorizationCodeFlowDelegate`, you can implement the appropriate methods to customize the URL:

```swift
func authentication<Flow: AuthorizationCodeFlow>(
    flow: Flow,
    customizeUrl urlComponents: inout URLComponents)
{
    urlComponents.queryItems?.append(URLQueryItem(name: "idp", value: myIdpString))
    urlComponents.fragment = "recover"
}
```
