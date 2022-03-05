# ``AuthFoundation``

Library that provides foundational features used by Okta's authentication libraries, as well as APIs used to work with tokens and user credentials. 

## Overview

AuthFoundation provides the fundamentals for interacting with Okta, and exposing features that enable day-to-day operations with a user's credentials.

You can use AuthFoundation when you want to:

* Manager, store, and use tokens and user information.
* Interact with supplementary native SDKs, such as WebAuthentication or OktaOAuth2.
* Introspect or monitor network activity, customize behavior, or other operations related to user interaction.

## Topics

### User Management

- <doc:ManagingUserCredentials>
- ``Token``
- ``Credential``
- ``UserInfo``

### OAuth2 Client Operations

- ``OAuth2Client``
- ``OAuth2ClientDelegate``
- ``OpenIdConfiguration``

### JWT and Token Verification

- ``JWT``
- ``JWK``
- ``JWKS``

### Customizations

- ``TimeCoordinator``
- ``CredentialDataSource``
- ``CredentialDataSourceDelegate``
- ``TokenStorage``
- ``TokenStorageDelegate``
- ``JWKStorage``
- ``JWTValidator``

### Networking

- ``APIClient``
- ``APIClientDelegate``
- ``APIContentType``
- ``APIRequest``
- ``APIRequestBody``
- ``APIRequestArgument``
- ``APIRequestMethod``
- ``APIResponse``
- ``APIAuthorization``
- ``JSONDecodable``
- ``Empty``

### Error Types

- ``APIClientError``
- ``OAuth2Error``
- ``OAuth2ServerError``
- ``OktaAPIError``
- ``CredentialError``
- ``TokenError``
- ``JWTValidatorError``

### Internals and mocking

- ``DelegateCollection``
- ``UsesDelegateCollection``
- ``URLSessionProtocol``
- ``URLSessionDataTaskProtocol``
- ``SDKVersion``
