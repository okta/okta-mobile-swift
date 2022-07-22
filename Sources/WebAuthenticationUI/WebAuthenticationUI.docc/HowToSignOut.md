# How To Sign Out

Determine the optimal approach to signing users out of your application.

When signing users out of your application, there are several options available to you, depending on how you integrate the SDK. These have to do with the use of ``WebAuthentication/ephemeralSession``, the use of Swift Concurrency, and whether or not the `Credential` or `Token` class is being used.

## Using The Browser

When signing in with ``WebAuthentication/ephemeralSession`` set to `false` (which is the default), the browser the user signs into will use a shared set of cookies. This enables your user to perform single sign-on across both web and mobile applications.

During sign-in, the user is presented with an alert like the following. This is to ensure your user can opt-in to enabling access to their shared browser from your application.

![Alert presented to a user during authentication](AuthenticationAlert)

In this scenario, to properly sign the user out, the session within the browser needs to be invalidated. You can do this using the following code:

```swift
try await WebAuthentication.shared?.signOut(from: view.window)
```

This will result in the browser being displayed to the user, along with the same alert shown above. Immediately after the browser is displayed, it should automatically dismiss when the session is invalidated.

## Using Ephemeral Sessions

If ``WebAuthentication/ephemeralSession`` is set to `true` when signing in, you do not need to use ``WebAuthentication/signOut(from:credential:)`` to sign your user out.  In this scenario, no browser session is stored within the browser's cookie storage.

To sign out in this scenario, the `Credential.revoke` method can be used directly to revoke the tokens assigned to the user.

```swift
try await Credential.default?.revoke()
```

## Removing Tokens from Storage

As a simplest approach, signing out can be as simple as removing the tokens from local storage.

```swift
try credential.remove()
```

It's worth noting however that this will not invalidate the tokens on the server, meaning if those tokens have been compromised in any way, they will still continue to remain valid past the lifetime of your application.

> Important: It is not recommended to follow this approach.
