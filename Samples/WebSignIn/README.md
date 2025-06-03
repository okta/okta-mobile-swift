# WebSignIn

## Abstract

Add web-based sign in and single sign-on that uses the token exchange flow from the OAuth 2.0 specification with the WebAuthenticationUI Library.

## Overview

The Okta Client SDK for Swift provides a libraries and utility classes that manage standard sign-on flows. The `WebAuthentication` class manages the web-based sign-on process, while the `TokenExchangeFlow` class manages the OAuth 2.0 token exchange flow used to implement Single Sign On (SSO).

The sample contains two different targets:

- **WebSignIn (iOS):** The iOS app that implements web-based sign on.
- **SingleSignOn (iOS):** A companion app that uses the account information from _WebSignIn (iOS)_ to sign the user on.

## Configuring the App

Update the `WebSignIn (iOS) > WebSignIn > Okta.plist` file with the information for your Okta Org Application Integration. See the [Readme in the Shared folder](../Shared/README.md#okta_property_list) for a the definition of the keys in Okta property list file.

> **IMPORTANT:** This sample requires a value for the optional `logoutRedirectUri`key. The `device_sso` scope should be included if you wish to try the SingleSignOn sample app.
   
## Related Resources

- For information on configuring the device SSO feature in your Okta Admin Console, see [Configure Native SSO for your Okta org](https://developer.okta.com/docs/guides/configure-native-sso/-/main/#configure-native-sso-for-your-okta-org).
- [Okta Client SDK for Swift](https://github.com/okta/okta-mobile-swift)
