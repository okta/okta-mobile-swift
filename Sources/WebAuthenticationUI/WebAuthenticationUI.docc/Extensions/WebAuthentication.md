# ``WebAuthenticationUI/WebAuthentication``

## Topics

### Essentials

- <doc:ConfiguringYourClient>
- ``shared``
- ``ephemeralSession``

### Initializers

- ``init()``
- ``init(plist:)``
- ``init(issuer:clientId:scopes:redirectUri:logoutRedirectUri:additionalParameters:)``
- ``init(loginFlow:logoutFlow:context:)``

### Sign In

- ``signIn(from:)``
- ``signIn(from:completion:)``

### Sign Out Using Credential

- <doc:HowToSignOut>
- ``signOut(from:credential:)``
- ``signOut(from:credential:completion:)``

### Sign Out Using Token

- <doc:HowToSignOut>
- ``signOut(from:token:)-2cj8w``
- ``signOut(from:token:)-6qrgc``
- ``signOut(from:token:completion:)-8o8xk``
- ``signOut(from:token:completion:)-4ae85``

### Sign In Using App Link

- ``resume(with:)-9xiuc``
- ``resume(with:)-5hhn1``

### Customizing OAuth2 Flows

- ``signInFlow``
- ``signOutFlow``
- ``context``

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

## Usage

Signing in and -out is intended to be simple using this class, with several options for configuring your client (see <doc:ConfiguringYourClient> for more information). Once your client is configured, it is available through a shared singleton property ``shared``, or can be directly accessed if you create an instance directly.

The ``signIn(from:)`` function (or ``signIn(from:completion:)`` for applications not using Swift Concurrency) presents a browser from the window supplied to the `from` argument, which the user can use to enter their account information.  After the sign in completes, the result is returned allowing your application to continue.

When signing a user out, the ``signOut(from:credential:)`` function similarly presents a browser to the user, in order to clear cookies and other browser state that is associated with the user's session.
