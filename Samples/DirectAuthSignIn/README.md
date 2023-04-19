# DirectAuthSignIn

## Abstract

Add native sign-in using Okta's Direct Authentication flow to your iOS app.

## Overview

The Okta Mobile SDK includes the OktaDirectAuth library, and the `DirectAuthenticationFlow` class which manages the process for performing native MFA sign in.

## Configuring the App

Update the `DirectAuthSignIn > DirectAuthSignIn > Okta.plist` file with the information for your Okta Org Application Integration. See the [Readme in the Shared folder](../Shared/README.md#okta_property_list) for a the definition of the keys in Okta property list file.

> **IMPORTANT:** The Direct Authentication API is currently an Early Access (EA) feature, and needs to be enabled in your account before it can be used.
   
## See Also

- DirectAuthSignIn > OktaDirectAuth > [DirectAuthenticationFlow](https://okta.github.io/okta-mobile-swift/development/oktadirectauth/documentation/oktadirectauth/directauthenticationflow/) in the Okta Mobile SDK documentation.
