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

- ``User``
- ``Token``
- ``UserInfo``
- ``UserError``
- ``TokenError``

### OAuth2 Client Operations

- ``OAuth2Client``
- ``OAuth2ClientDelegate``
- ``OAuth2Error``
- ``OAuth2ServerError``
- ``OpenIdConfiguration``

### Customizations

- ``TimeCoordinator``
- ``UserDataSource``
- ``UserDataSourceDelegate``
- ``TokenStorage``
- ``TokenStorageDelegate``

### Networking

- ``APIClient``
- ``APIClientDelegate``
- ``APIClientError``
- ``APIContentType``
- ``APIRequest``
- ``APIRequestBody``
- ``APIRequestArgument``
- ``APIRequestMethod``
- ``APIResponse``
- ``APIAuthorization``
- ``JSONDecodable``
- ``OktaAPIError``
- ``Empty``

### Internals and mocking

- ``DelegateCollection``
- ``UsesDelegateCollection``
- ``URLSessionProtocol``
- ``URLSessionDataTaskProtocol``
- ``SDKVersion``
