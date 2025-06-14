# Migration Guide

## Migrating from Okta Client SDK 1.x

The Okta Client SDK for Swift (formerly named "Okta Mobile SDK for Swift") introduced a number of changes in the 2.0 release, which had some impacts to public API names and function signatures. Many of these APIs have deprecation warnings to enable Xcode to automatically migrate your code, but in some areas this was not possible.

The primary changes and introductions are:

### Redirect URI handling

The `redirectUri` arguments to various APIs have moved to the `OAuth2Client`'s Configuration object.

As a result, Authentication Flows that accepted the `redirectUri` or `logoutRedirectUri` to their `start` functions should now be passed to the convenience initializers, or assigned to the `OAuth2Client` configuration directly.

### Authentication Flow Context

All authentication flows now contain a `Context` object type which stores all customizations and runtime state for an individual session of an Authentication Flow. This means that a single instance of a flow can be configured with settings appropriate for the use of that flow, while a user's choices or sign-in session information may be assigned to the Context.

The use of this new type allows for much more expressive assignment of configuration values while simplifying runtime data consistency. This includes the introduction of support for:

* Supplying Authentication Context Reference (`acr_values`)
* Customizing the `maxAge`
* Specifying a custom `state` value
* Developer conveniences for richer assignment of options to the Authorization Code Flow redirect sign-in class, such as "login_hint", "display", "prompt", and so forth
* Session-specific additional key/value parameters to supply to the flow

If you use any of these early support for these features in your current application, you should instead assign these values to the appropriate Context object. 

### OktaOAuth2 renamed to OAuth2Auth

For consistency with other libraries related to authentication, the OAuth2 authentication library was renamed to OAuth2Auth.

Additionally, since the features supported in this library are standards-based and should theoretically work with any compliant Authorization Server (AS), the `Okta` prefix has been dropped from this library.

### OktaIdx renamed OktaIdxAuth and moved to the monorepo

The OktaIdx authentication library is built upon the common AuthFoundation library within this repository, yet for historical reasons it has traditionally resided within its own `okta-idx-swift` repository on Github.  This posed a number of technical challenges during release, and has been a frequent source of confusion.

As a result, the git revision history has been merged within the `okta-mobile-swift` repository, and its library has been integrated into the overall monorepo.

Due to version incompatibility between the OktaIdx SDK in its original repository (which was already at a 3.x major version), and to remain consistent with other authentication libraries in this SDK, this library was renamed to OktaIdxAuth.   
