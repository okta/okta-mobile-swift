# ``AuthFoundation``

Library that provides foundational features used by Okta's authentication libraries, as well as APIs used to work with tokens and user credentials. 

## Overview

AuthFoundation provides the fundamentals for interacting with Okta, and exposing features that enable day-to-day operations with a user's credentials.

You can use AuthFoundation when you want to:

* Manage, store, and use tokens and user information.
* Interact with supplementary native SDKs, such as WebAuthenticationUI or OktaOAuth2.
* Introspect or monitor network activity, customize behavior, or other operations related to user interaction.

## Topics

### Essentials

- ``Credential``
- <doc:ManagingUserCredentials>

### Token Information

- ``Token``
- ``UserInfo``
- ``TokenInfo``

### OAuth2 Client Operations

- ``OAuth2Client``
- ``OAuth2ClientDelegate``
- ``OpenIdConfiguration``
- ``AuthenticationMethod``
- ``AuthenticationFlow``
- ``AuthenticationDelegate``
- ``OAuth2TokenRequest``
- ``GrantType``
- ``PKCE``

### JWT and Token Verification

- ``JWT``
- ``JWK``
- ``JWKS``
- ``JWTClaim``
- ``HasClaims``
- ``JSONClaimContainer``
- ``ClaimConvertable``
- ``IsClaim``
- ``Expires``

### Security

- ``Keychain``
- ``KeychainAuthenticationContext``
- ``TokenAuthenticationContext``

### Customizations

- <doc:CustomizingNetworkRequests>
- ``TimeCoordinator``
- ``CredentialCoordinator``
- ``CredentialDataSource``
- ``CredentialDataSourceDelegate``
- ``TokenStorage``
- ``TokenStorageDelegate``
- ``JWKValidator``
- ``TokenHashValidator``
- ``IDTokenValidator``
- ``IDTokenValidatorContext``

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
- ``APIResponseResult``
- ``APIRateLimit``
- ``APIRetry``
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
- ``JSONValueError``

### Migration and versioning

- ``SDKVersion``
- ``SDKVersionMigrator``
- ``Version``

### Internals and mocking

- ``DelegateCollection``
- ``UsesDelegateCollection``
- ``URLSessionProtocol``
- ``URLSessionDataTaskProtocol``
- ``Weak``
- ``WeakCollection``
