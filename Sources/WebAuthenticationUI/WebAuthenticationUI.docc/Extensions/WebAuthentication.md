# ``WebAuthenticationUI/WebAuthentication``

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

## Usage

Signing in and -out is intended to be simple using this class, with several options for configuring your client (see <doc:ConfiguringYourClient> for more information). Once your client is configured, it is available through a shared singleton property ``shared``, or can be directly accessed if you create an instance directly.

The ``signIn(from:)`` function (or ``signIn(from:completion:)`` for applications not using Swift Concurrency) presents a browser from the window supplied to the `from` argument, which the user can use to enter their account information.  After the sign in completes, the result is returned allowing your application to continue.

When signing a user out, the ``signOut(from:credential:)`` function similarly presents a browser to the user, in order to clear cookies and other browser state that is associated with the user's session.
