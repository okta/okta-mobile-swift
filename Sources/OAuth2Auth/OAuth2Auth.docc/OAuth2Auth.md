# ``OAuth2Auth``

Interact with Okta's OAuth2 APIs to authenticate users, and interact with user resources.

## Overview

The Okta OAuth2 framework provides classes and methods that represent the variety of authentication flows and utility APIs used to sign users into your applications. This framework can either be used to customize the sign in process when being used through the BrowserSignin framework, or can be used directly to create custom sign-in experiences.

You can use OAuth2Auth when you want to:

* Customize the sign in workflow for BrowserSignin-based applications, through the use of an ``AuthorizationCodeFlowDelegate``.
* Implement your own browser-based sign in workflow directly using ``AuthorizationCodeFlow``.
* Sign users in using headless or non-browser-based workflows, such as Device SSO, Device Authentication, Resource Owner (aka Username/Password sign on), etc.
* Customize outbound network requests through the use of the ``OAuth2Auth`` API delegate.

## Topics

### Essentials
- <doc:IntroductionToAuthenticationFlows>

### Authorization Code Flow

- ``AuthorizationCodeFlow``
- ``AuthorizationCodeFlowDelegate``
- ``AuthorizationCodeFlow/Context-swift.struct``
- ``SessionLogoutFlow``
- ``SessionLogoutFlow/Context-swift.struct``
- ``SessionLogoutFlowDelegate``

### Device Authorization Flow

- ``DeviceAuthorizationFlow``
- ``DeviceAuthorizationFlowDelegate``
- ``DeviceAuthorizationFlow/Context-swift.struct``

### Token Exchange Flow

- ``TokenExchangeFlow``
- ``TokenExchangeFlow/Audience-swift.enum``

### Resource Owner Flow

- ``ResourceOwnerFlow``

### Session Token Flow

- ``SessionTokenFlow``
