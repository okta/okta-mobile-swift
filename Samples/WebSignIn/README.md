# WebSignIn Samples

This sample contains three separate sample application schemes:

## WebSignIn (iOS)

This sample demonstrates web authentication using the WebAuthenticationUI library.  To get started, open the `Okta.plist` file and update its contents with your application's configuration settings to run the sample.

 Key | Required | Description |
---|---|---
`issuer` | ✔ | Issuer URL for the client.
`clientId` | ✔ | Client ID for the Okta application.
`scopes` | ✔ | Scopes the client is requesting.
`redirectUri` | ✔  | Redirect URI for the Okta application.
`logoutRedirectUri` | | Logout URI used for the Okta application.
Other... | | Any additional keys will be passed to the `additionalParameters` argument of the initializer.

## SingleSignOn (iOS)

This application demonstrates Device SSO authentication (also referred to as `TokenExchangeFlow` within OktaOAuth2). This sample works in conjuction with the WebSignIn (iOS) sample. 

Configure the client by opening the `SingleSignOnViewController.swift` file, and input the client's settings.

If the `Okta.plist` file (from the WebSignIn sample) is configured with the `device_sso` scope, the device secret that is created when authenticating using the web sign in sample is saved to a common keychain entry within a shared App Group.

After signing in, launch the SingleSignOn demo application, and your user should be logged in automatically.

## WebSignIn (macOS)

This is a counterpart to the iOS web sign in sample, and demonstrates a simple macOS SwiftUI application, authenticating over the web.  This application's `Okta.plist` file is shared with the iOS application.
