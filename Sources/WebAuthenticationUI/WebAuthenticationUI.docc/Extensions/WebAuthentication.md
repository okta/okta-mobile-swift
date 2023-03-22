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

- ``signIn(from:options:)``
- ``signIn(from:options:completion:)``

### Sign Out Using Credential

- <doc:HowToSignOut>
- ``signOut(from:credential:options:)``
- ``signOut(from:credential:options:completion:)``

### Sign Out Using Token

- <doc:HowToSignOut>
- ``signOut(from:token:options:)-4x9ic``
- ``signOut(from:token:options:)-33i36``
- ``signOut(from:token:options:completion:)-3q66k``
- ``signOut(from:token:options:completion:)-2jka2``

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

The ``signIn(from:options:)`` function (or ``signIn(from:options:completion:)`` for applications not using Swift Concurrency) presents a browser from the window supplied to the `from` argument, which the user can use to enter their account information.  After the sign in completes, the result is returned allowing your application to continue.

When signing a user out, the ``signOut(from:credential:options:)`` function similarly presents a browser to the user, in order to clear cookies and other browser state that is associated with the user's session.
