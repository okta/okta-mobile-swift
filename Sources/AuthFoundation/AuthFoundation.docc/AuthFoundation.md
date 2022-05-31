# ``AuthFoundation``

Library that provides foundational features used by Okta's authentication libraries, as well as APIs used to work with tokens and user credentials. 

## Overview

AuthFoundation provides the fundamentals for interacting with Okta, and exposing features that enable day-to-day operations with a user's credentials.

You can use AuthFoundation when you want to:

* Manage, store, and use tokens and user information.
* Interact with supplementary native SDKs, such as WebAuthenticationUI or OktaOAuth2.
* Introspect or monitor network activity, customize behavior, or other operations related to user interaction.

## Topics

### User Management

- <doc:ManagingUserCredentials>
- ``Token``
- ``Credential``
- ``UserInfo``
- ``TokenInfo``

### OAuth2 Client Operations

- ``OAuth2Client``
- ``OAuth2ClientDelegate``
- ``OpenIdConfiguration``
- ``AuthenticationFlow``
- ``AuthenticationDelegate``
- ``OAuth2TokenRequest``
- ``GrantType``
- ``PKCE``

### JWT and Token Verification

- ``JWT``
- ``JWK``
- ``JWKS``
- ``Claim``
- ``HasClaims``
- ``ClaimContainer``
- ``Expires``

### Security

- ``Keychain``

### Customizations

- <doc:CustomizingNetworkRequests>
- ``TimeCoordinator``
- ``CredentialCoordinator``
- ``CredentialDataSource``
- ``CredentialDataSourceDelegate``
- ``TokenStorage``
- ``TokenStorageDelegate``
- ``JWKValidator``
- ``AccessTokenValidator``
- ``IDTokenValidator``

### Networking

- ``APIClient``
- ``APIClientDelegate``
- ``APIClientConfiguration``
- ``APIContentType``
- ``APIRequest``
- ``APIRequestBody``
- ``APIRequestArgument``
- ``APIRequestMethod``
- ``APIResponse``
- ``APIAuthorization``
- ``APIParsingContext``
- ``OAuth2APIRequest``
- ``JSONDecodable``
- ``Empty``

### Error Types

- ``APIClientError``
- ``OAuth2Error``
- ``OAuth2ServerError``
- ``OktaAPIError``
- ``CredentialError``
- ``TokenError``
- ``JWTError``
- ``KeychainError``
- ``AuthenticationError``

### Migration and versioning

- ``SDKVersion``
- ``SDKVersionMigrator``

### Internals and mocking

- ``DelegateCollection``
- ``UsesDelegateCollection``
- ``URLSessionProtocol``
- ``URLSessionDataTaskProtocol``
- ``Weak``
- ``WeakCollection``
- ``TimeSensitive``
