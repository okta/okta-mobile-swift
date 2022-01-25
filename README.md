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

## Installation

To get started, you will need:

* An Okta account, called an _organization_ (sign up for a free [developer organization](https://developer.okta.com/signup) if you need one).
* Xcode targeting iOS 9 and above.

### Swift Package Manager

Add the following to the `dependencies` attribute defined in your `Package.swift` file. You can select the version using the `majorVersion` and `minor` parameters. For example:

```swift
dependencies: [
    .Package(url: "https://github.com/okta/okta-mobile-swift.git", majorVersion: <majorVersion>, minor: <minor>)
]
```

## Usage

This SDK consists of several different libraries, each with their own detailed documentation.

- AuthFoundation -- Common classes for managing credentials, and used as a foundation for other libraries.
- OktaOAuth2 -- OAuth2 authentication capabilities for authenticating users.
- WebAuthenticationUI -- Authenticate users using web-based OIDC flows.

## Development

### Running Tests

## Support Policy

This policy defines the extent of the support for Xcode, Swift, and platform (iOS, macOS, tvOS, and watchOS) versions.

### Xcode

The only supported versions of Xcode are those that can be currently used to submit apps to the App Store. Once a Xcode version becomes unsupported, dropping support for it will not be considered a breaking change, and will be done in a minor release.

### Swift

The minimum supported Swift 5 minor version is the one released with the oldest-supported Xcode version. Once a Swift 5 minor becomes unsupported, dropping support for it will not be considered a breaking change, and will be done in a minor release.

### Platforms

Only the last 4 major platform versions are supported, starting from:

- iOS 12
- macOS 10.15
- Catalyst 13
- tvOS 12
- watchOS 6.2

Once a platform version becomes unsupported, dropping support for it will not be considered a breaking change, and will be done in a minor release. E.g. iOS 12 will cease to be supported when iOS 16 gets released, and might be dropped in a minor release.

In the case of macOS, the yearly named releases are considered a major platform version for the purposes of this Policy, regardless of the actual version numbers.

> *Note:* Older OS versions will be supported in a best-effort manner. Unless there are API limitations that prevent the SDK from working effectively on older OS versions, the minimum requirements will not be changed.

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
