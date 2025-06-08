# ``AuthFoundation``

Library that provides foundational features used by Okta's authentication libraries, as well as APIs used to work with tokens and user credentials. 

## Overview

AuthFoundation provides the fundamentals for interacting with Okta, and exposing features that enable day-to-day operations with a user's credentials.

You can use AuthFoundation when you want to:

* Manage, store, and use tokens and user information.
* Interact with supplementary native SDKs, such as WebAuthenticationUI or OAuth2Auth.
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
- ``AuthenticationContext``
- ``AuthenticationDelegate``
- ``StandardAuthenticationContext``
- ``OAuth2TokenRequest``
- ``GrantType``
- ``PKCE``

### JWT and Token Verification

- <doc:WorkingWithClaims>
- ``JWT``
- ``JWK``
- ``JWKS``
- ``JWTClaim``
- ``HasClaims``
- ``ClaimCollection``
- ``JSONClaimContainer``
- ``JSON``
- ``AnyJSON``
- ``JSONRepresentable``
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

- ``APIAuthorization``
- ``APIClientConfiguration``
- ``APIClientDelegate``
- ``APIClient``
- ``APIContentType``
- ``APIParsingContext``
- ``APIRateLimit``
- ``APIRequestArgument``
- ``APIRequestBody``
- ``APIRequestMethod``
- ``APIRequest``
- ``APIResponseResult``
- ``APIResponse``
- ``APIRetry``
- ``Empty``
- ``JSONDecodable``
- ``OAuth2APIRequest``
- ``OAuth2APIRequestCategory``
- ``AuthenticationFlowRequest``
- ``ProvidesOAuth2Parameters``

### Error Types

- ``APIClientError``
- ``ClaimError``
- ``CredentialError``
- ``JSONError``
- ``JWTError``
- ``KeychainError``
- ``OAuth2Error``
- ``OAuth2ServerError``
- ``OktaAPIError``
- ``TokenError``

### Migration and versioning

- ``Migration``
- ``SDKVersion``
- ``SDKVersionMigrator``

### Internals and Debugging

- ``DelegateCollection``
- ``DebugAPIRequestObserver``
- ``URLSessionDataTaskProtocol``
- ``URLSessionProtocol``
- ``UsesDelegateCollection``
- ``WeakCollection``
- ``Weak``
