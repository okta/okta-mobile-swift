# Managing User Credentials

Store, retrieve, and change user credentials within your application.

## Overview

The primary goal of using authentication APIs is to ultimately receive credentials for your users, allowing your them to do something with your application. If you don't have some way to save and retrieve those credentials for later use, your users would need to sign into your application every time they opened it.

Since no two applications are alike, and usage patterns vary wildly, Okta's AuthFoundation library exposes several features that enable you to access and manage user credentials conveniently, while still affording you the ability to customize behavior to suit your needs.

## Introduction to the Credential class

Within AuthFoundation a ``Token`` instance is used to store information related to a user's tokens, in particular the ``Token/accessToken``, which is used to perform authenticated requests. This class conforms to Codable, so it can be persisted across app launches to keep your user signed in. But this can be cumbersome to use on a day-to-day basis, so to simplify your development workflow, the ``Credential`` class exists.

Instances of ``Credential`` not only contain a reference to that user's ``Credential/token``, but exposes convenience methods and properties to simplify common operations, such as ``Credential/refresh()``, ``Credential/userInfo()``, or ``Credential/revoke(type:)``. To ensure these operations can function, a ``Credential/oauth2`` client is automatically created on your behalf, which can be used to perform other operations as needed.

## Storing credentials

When you first receive a ``Token``, you can use the ``Credential/store(_:tags:security:)`` static function to save the token in local storage. This function lets you supply optional tags to assign to the token to simplify the process of retrieving those credentials at a later date, or security settings to control how the token is stored.

If you know the unique ID for a given token, you can use the ``Credential/with(id:prompt:authenticationContext:)`` function to retrieve an individual credential. The optional `prompt` and `authenticationContext` arguments can be used to supply additional information when accessing tokens secured behind biometrics, with an optional `LAContext`.

When multiple credentials are stored, the ``Credential/find(where:prompt:authenticationContext:)`` method can be used to retrieve credentials based on custom tags, or claims defined within the credential's ID token.

## Working with the default credential

Once your user signs in, you as an application developer will want to do something with that user's credentials. While you can retain the credential object, and can pass it around throughout your application, it is often convenient to have singleton access to this common object.

The ``Credential/default`` static property does just that, providing common access to the default credential for the application. This value will additionally be persisted across app launches, ensuring you can quickly and conveniently determine if a sign in screen needs to be presented, or if a user is already present.

As a convenience, if no other tokens are present in your application, the first ``Token`` stored will automatically be assigned as the default. The ``Credential/default`` value will automatically be set to `nil` when its credential is removed using ``Credential/remove()``.

### Changing the default credential

If at some point you would like to change the default credential, or sign in a new user, you can simply set a new value to this property, and the value will be persisted for the next application launch.

One challenge in applications is responding to change, particularly when transitioning between signed-out and -in. To that end, a NotificationCenter notification is broadcast whenever the default credential changes.

```swift
NotificationCenter.default.addObserver(forName: .defaultCredentialChanged,
                                       object: nil,
                                       queue: .main) { notification in
    guard let credential = notification.object as? Credential else {
        // User signed out
        return
    }
    
    // Do something with the user
}
```

## Removing credentials

When you no longer need a credential (usually when a user chooses to sign out), there are two options within Credential:

* ``Credential/revoke(type:)``
* ``Credential/remove()``
* `WebAuthentication/signOut(from:credential:)` (when using WebAuthenticationUI)

### When to use `signOut`

When authenticating using a web browser, there are circumstances where cookies representing the user's session are saved within the browser. To properly sign out in this situation, it's important to use the `WebAuthentication` class' `signOut` function to ensure those cookies are properly reset.

### When to use `revoke`

When authenticating a user via a browser without cookies (see the `ephemeralSession` option on `WebAuthentication`), or when authenticating using a non-browser flow, signing a user out is simpler when using the ``Credential/revoke(type:)`` function. See that function's documentation for more information.

### When to use `remove`

Finally, at a minimum you can use the ``Credential/remove()`` function to simply remove that credential from storage. This will effectively make the application forget those tokens.

> Important: Removing a credential from your application won't invalidate it on the server. For that reason it's recommended to use ``Credential/revoke(type:)`` wherever possible.

## Managing multiple credentials

Changing the ``Credential/default`` property doesn't remove the old value from storage. Instead, all credentials that are stored are available. This can enable multiple user credentials to be used simultaneously.

### Working with multiple credentials

Several approachs to finding and using credentials are provided, depending upon your application use-case. These facilities simplifies the process of assigning different credentials to different tasks within your application.

#### Finding credentials by ID

All tokens are automatically assigned a unique ID it can be identified by. This can be seen in the ``Token/id`` (as well as through the ``Credential/id`` property). This identifier may be used with the ``Credential/with(id:prompt:authenticationContext:)`` function.

```swift
if let credential = try Credential.with(id: serviceTokenId) {
    // Do something with the credential
}
```

The list of all stored IDs is available through the ``Credential/allIDs`` static property.

#### Finding credentials by developer-assigned tags

When storing tokens, the ``Credential/store(_:tags:security:)`` function accepts an optional collection of tags you can use to identify the purpose of different tokens.  The ``Credential/find(where:prompt:authenticationContext:)`` function allows you to query tokens based on those tags at a later date.  Furthermore, those tags can later be updated by changing the credential's ``Credential/tags`` property.

```swift
try Credential.store(token: newToken, tags: ["service": "purchase"])

// Later ...

if let credential = try Credential.find(where: { $0.tags["service"] == "purchase" }).first {
    // Use the credential
}
```

#### Finding credentials by ID Token claims

If a token contains a valid ``Token/idToken``, the claims it represents are available within the ``Credential/find(where:prompt:authenticationContext:)`` expression. The object returned within that expression supports the ``HasClaims`` protocol, meaning its values can be queried within that filter.

```swift
let userCredentials = try Credential.find { metadata in
    metadata.subject == "jane.doe@example.com"
}
```
