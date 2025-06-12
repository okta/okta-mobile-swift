# ``AuthFoundation/OAuth2Client``

This class serves two purposes:
1. Expose high-level actions a client can perform against an OAuth2 service.
2. Connect authentication flows to the OAuth2 servers they intend to authenticate against.

Authentication flows represent the variety of ways authentication can occur, and in many cases involves multiple discrete steps. These often require interaction with individual actions (such as fetching OpenID configuration, accessing JWKS keys, and exchanging tokens), so these are encapsulated within the OAuth2Client for code sharing and ease of use.

This class is defined within AuthFoundation, but is intended to be extended by additional libraries, and is primarily used to perform operations against an OAuth2 server for the purposes of:

* Refreshing access tokens
* Introspecting a token
* Fetching user info for a given token
* Revoking tokens
* Fetching OpenID configuration or JWKS key information

These form the foundation of the ``Credential`` class, many of these operations being handled automatically for you. However, the ``OAuth2Client`` class can be used directly by the developer if custom usage patterns are needed.

## Using a custom URLSession

When working with an ``OAuth2Client``, either for the purposes of authenticating a new user or when using an existing token, there are circumstances where you may want to utilize your own URLSession instance. These two different use-cases can be addressed through two different patterns.

### Authenticating using a custom URLSession

Within the OAuth2Auth library, the initializers for the various authentication flows can accept a custom ``OAuth2Client`` instance that would then be used for all API requests made to process the login. The client ID and other settings from the ``OAuth2Client`` are used within that flow.

### Using a custom URLSession for existing token lifecycle

When using the ``Credential`` class to manage operations with a user's ``Token``, a ``OAuth2Client`` object is associated with the credential using the ``Credential/oauth2`` property. This value is automatically created for you when the Credential is instantiated. 

If you want to manually assign your own ``OAuth2Client`` to a credential, you can either:

1. Create a credential manually using the ``Credential/init(token:oauth2:)`` initializer. Note that you'll need to ensure the token and client's configuration match (e.g. the same client ID and base URL), otherwise an exception may be thrown.
2. Implement the ``CredentialDataSource`` protocol and supply a custom URLSession instance in the ``CredentialDataSource/urlSession(for:)-4uxwd`` method.
