[<img src="https://aws1.discourse-cdn.com/standard14/uploads/oktadev/original/1X/0c6402653dfb70edc661d4976a43a46f33e5e919.png" align="right" width="256px"/>](https://devforum.okta.com/)

[![Support](https://img.shields.io/badge/support-Developer%20Forum-blue.svg)][devforum]
[![API Reference](https://img.shields.io/badge/docs-reference-lightgrey.svg)][swiftdocs]

# Okta Mobile SDK for Swift

**Table of Contents**

<!-- TOC depthFrom:2 depthTo:3 -->
<!-- /TOC -->

## Release status

This library uses semantic versioning and follows Okta's [Library Version Policy][okta-library-versioning].

| Version | Status                             |
| ------- | ---------------------------------- |
| 0.1.0   | ✔️ Beta                             |

The latest release can always be found on the [releases page][github-releases].

## Need help?
 
If you run into problems using the SDK, you can:
 
* Ask questions on the [Okta Developer Forums][devforum]
* Post [issues][github-issues] here on GitHub (for code errors)

## Getting Started

To get started, you will need:

* An Okta account, called an _organization_ (sign up for a free [developer organization](https://developer.okta.com/signup) if you need one).
* An Okta Application, configured as a Native App. This is done from the Okta Developer Console. When following the wizard, use the default properties. They are designed to work with our sample applications.
* Xcode 13.x, targeting one of the supported platforms and target versions (see the [support-policy](Support Policy) below).

## Install

### Swift Package Manager

Add the following to the `dependencies` attribute defined in your `Package.swift` file. You can select the version using the `majorVersion` and `minor` parameters. For example:

```swift
dependencies: [
    .Package(url: "https://github.com/okta/okta-mobile-swift.git", majorVersion: <majorVersion>, minor: <minor>)
]
```

## Usage Guide

This SDK consists of several different libraries, each with their own detailed documentation.

- AuthFoundation -- Common classes for managing credentials, and used as a foundation for other libraries.
- OktaOAuth2 -- OAuth2 authentication capabilities for authenticating users.
- WebAuthenticationUI -- Authenticate users using web-based OIDC flows.

The use of this SDK enables you to build or support a myriad of different authentication flows and approaches. To simplify getting started, here are a few samples to demonstrate its usage.

### Web Authentication using OIDC

The simplest way to integrate authentication in your app is with OIDC through a web browser, using the Authorization Code Flow grant.

#### Configure your OIDC Settings

Before authenticating your user, you need to create your `AuthorizationCodeFlow.Configuration`, using the settings defined in your application in the Okta Developer Console. The simplest approach is to use a `Okta.plist` configuration file to specify these settings. Ensure one is created with the following fields:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>issuer</key>
    <string>https://{yourOktaDomain}.com/oauth2/default</string>
    <key>clientId</key>
    <string>{clientId}</string>
    <key>redirectUri</key>
    <string>{redirectUri}</string>
    <key>logoutRedirectUri</key>
    <string>{logoutRedirectUri}</string>
    <key>scopes</key>
    <string>openid profile offline_access</string>
  </dict>
</plist>
```

Alternatively, you can supply those values to the constructor the `WebAuthentication` we're about to discuss in the next section.

#### Create a Web Authentication session

Once you've configured your application settings within your `Okta.plist` file, a shared configuration will automatically be made available through the `WebAuthentication.shared` singleton property. With that in place, you can use the convenience `WebAuthentication.signIn(from:)` method to prompt the user to sign in.

```swift
import WebAuthenticationUI

func signIn() async {
    let token = try await WebAuthentication.signIn(from: view.window)
    let credentnial = Credential.for(token: token)
}
```

The `signIn(from:)` function will return a token and, by using the `Credential` class, you can save the token and use it within your application.

## Development

### Running Tests

## Support Policy

This policy defines the extent of the support for Xcode, Swift, and platform (iOS, macOS, tvOS, and watchOS) versions.

### Xcode

The only supported versions of Xcode are those that can be currently used to submit apps to the App Store. Once a Xcode version becomes unsupported, dropping support for it will not be considered a breaking change, and will be done in a minor release.

### Swift

The minimum supported Swift 5 minor version is the one released with the oldest-supported Xcode version. Once a Swift 5 minor becomes unsupported, dropping support for it will not be considered a breaking change, and will be done in a minor release.

### Platforms

Only the last 4 major platform versions are officially supported, starting from:

- iOS 12
- macOS 10.15
- Catalyst 13
- tvOS 12
- watchOS 6.2

Once a platform version becomes unsupported, dropping support for it will not be considered a breaking change, and will be done in a minor release. E.g. iOS 12 will cease to be supported when iOS 16 gets released, and might be dropped in a minor release.

In the case of macOS, the yearly named releases are considered a major platform version for the purposes of this Policy, regardless of the actual version numbers.

> *Note:* Older OS versions will be supported in a best-effort manner. Unless there are API limitations that prevent the SDK from working effectively on older OS versions, the minimum requirements will not be changed.
> 
> Additionally, Linux compatibility is considered best-effort, and is not officially supported.

## Known issues

## Contributing
 
We are happy to accept contributions and PRs! Please see the [contribution guide](CONTRIBUTING.md) to understand how to structure a contribution.

[devforum]: https://devforum.okta.com/
[swiftdocs]: https://developer.okta.com/okta-mobile-swift/latest/
[lang-landing]: https://developer.okta.com/code/swift/
[github-issues]: https://github.com/okta/okta-mobile-swift/issues
[github-releases]: https://github.com/okta/okta-mobile-swift/releases
[Rate Limiting at Okta]: https://developer.okta.com/docs/api/getting_started/rate-limits
[okta-library-versioning]: https://developer.okta.com/code/library-versions
[support-policy]: #support-policy
