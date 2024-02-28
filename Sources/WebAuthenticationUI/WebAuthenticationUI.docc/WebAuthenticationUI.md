# ``WebAuthenticationUI``

Make it easy to enable users to sign in to your app through browser-based sign on.

## Overview

Use the WebAuthenticationUI framework to quickly and easily integrate user sign on within your application.

* Simple API for initiating a browser-based sign-in flow.
* Provides convenient hooks for customizing the sign on process.
* Utilizes the appropriate underlying platform services to sign on, regardless of which iOS or macOS version is being used.
* Supports single sign-on (SSO) experiences across applications.

## Platform Compatibility

To maximize the number of platforms and OS versions your application can support, this SDK builds in a compatibility support for legacy iOS and macOS versions.

Platform | Versions | Authentication Controller |
---|---|---
iOS | 10.0 - 10.x | SFSafariViewController 
iOS | 11.0 | SFAuthenticationSession 
iOS | 12.0 - Current | ASWebAuthenticationSession 
macOS | 10.15 - Current | ASWebAuthenticationSession
macOS Catalyst  | 13.0 - Current | ASWebAuthenticationSession

## Topics

### Essentials

- ``WebAuthentication``
- <doc:ConfiguringYourClient>

### Customizations

- <doc:CustomizingAuthorizationURL>
