# ``OktaOAuth2``

Interact with Okta's OAuth2 APIs to authenticate users, and interact with user resources.

## Overview

The Okta OAuth2 framework provides classes and methods that represent the variety of authentication flows and utility APIs used to sign users into your applications. This framework can either be used to customize the sign in process when being used through the WebAuthenticationUI framework, or can be used directly to create custom sign-in experiences.

You can use OktaOAuth2 when you want to:

* Customize the sign in workflow for WebAuthenticationUI-based applications, through the use of an ``AuthorizationCodeFlowDelegate``.
* Implement your own browser-based sign in workflow directly using ``AuthorizationCodeFlow``.
* Sign users in using headless or non-browser-based workflows, such as Device SSO, Device Authentication, Resource Owner (aka Username/Password sign on), etc.
* Customize outbound network requests through the use of the ``OktaOAuth2`` API delegate.

## Topics

### Authorization Code Flow

- ``AuthorizationCodeFlow``
- ``AuthorizationCodeFlowDelegate``
- ``SessionLogoutFlow``
- ``SessionLogoutFlowDelegate``

### Device Authorization Flow

- ``DeviceAuthorizationFlow``
- ``DeviceAuthorizationFlowDelegate``

### Token Exchange Flow

- ``TokenExchangeFlow``

### Resource Owner Flow

- ``ResourceOwnerFlow``
