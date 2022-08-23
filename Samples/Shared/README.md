# Shared Sample Resources

This directory contains shared resources used by the various sample applications in this repo.

## Common

Contains common classes and protocols used by either the automated test targets, or sample applications, to prevent unnecessary duplication of effort. In particular, this contains the files used to display the user's profile and account information when sign in is successful.

## Shared Secrets / Credentials

This directory contains configuratino files used by the various sample applications within this repository for storing per-developer secrets. This can simplify the time it takes for a developer to experiment with the various samples, without needing to update the same client credentials across multiple files.

> **NOTE:** To ensure secrets don't accidentally get committed, please refer to the "Protecting Test Configuration" section of the main [SDK README](../../README.md).

### `Okta.plist`

This configuration file is used by various sign in flows, and is a convenient way to store client configuration. 

The SDK expects the following keys to be present:

 Key | Required | Description |
---|---|---
`issuer` | ✔ | Issuer URL for the client.
`clientId` | ✔ | Client ID for the Okta application.
`scopes` | ✔ | Scopes the client is requesting.
`redirectUri` |    | Redirect URI for the Okta application.
`logoutRedirectUri` | | Logout URI used for the Okta application.
Other... | | Any additional keys will be passed to the `additionalParameters` argument of the initializer.

### `TestConfiguration.xcconfig`

This configuration file is used solely for the benefit of automated testing. When running any of the UI test targets within these sample repos, this configuration file is used to supply client settings and user credentials to enable the tests to authenticate against a live organization in Okta.
