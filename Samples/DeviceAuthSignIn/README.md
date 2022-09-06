# DeviceAuthSignIn

## Abstract

Add sign-in using the OAuth 2.0 device authorization grant flow to your tvOS app.

## Overview

The Okta Mobile SDK for Swift provides a number of utility classes that manage standard sign-on flows. The `DeviceAuthorizationFlow` class manages the OAuth 2.0 device authorization code flow.

The sample contains two different targets:

- **DeviceAuthSignIn(tvOS):** The tvOS app that implements the sign-in flow.
- **DeviceAuthSignIn(iOS):** An implementation of the app on iOS used for automated testing.

## Configuring the App

Add the issuer URL for your Okta org and the client ID for your Okta Application Integration to the tvOS app to the file DeviceAuthSignIn (tvOS) > DeviceAuthSignIn > ViewController.swift. There are two placeholders in that file:

- **`domain`:** The domain of your registered Okta org followed by `/oauth2/default`, such as `https://dev-1234567.okta.com/oauth2/default`.
- **`client_id`:** The client ID from the Application Integration in the Okta Admin console, such as `0ux3rutxocxFX9xyz3t9`.

## See Also

- OktaBrowserSignIn > OktaOAuth2 > [Introduction to Authentication Flows](https://okta.github.io/okta-mobile-swift/development/oktaoauth2/documentation/oktaoauth2/introductiontoauthenticationflows) in the Okta Mobile SDK documentation.

## Related Resources

- For information on configuring the device authorization grant flow in your Okta Admin Console, see [Configure Device Authorization Grant Flow](https://developer.okta.com/docs/guides/device-authorization-grant/main/#configure-the-authorization-server-policy-rule-for-device-authorization).
- [Okta Mobile SDK for Swift](https://github.com/okta/okta-mobile-swift)
