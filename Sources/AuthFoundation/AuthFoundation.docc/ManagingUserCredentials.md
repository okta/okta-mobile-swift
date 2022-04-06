# Managing User Credentials

Store, retrieve, and change user credentials within your application.

## Overview

The primary goal of using authentication APIs is to ultimately receive credentials for your users, allowing your them to do something with your application. If you don't have some way to save and retrieve those credentials for later use, your users would need to sign into your application every time they opened it.

Since no two applications are alike, and usage patterns vary wildly, Okta's AuthFoundation library exposes several features that enable you to access and manage user credentials conveniently, while still affording you the ability to customize behavior to suit your needs.

## Introduction to the Credential class

Within AuthFoundation a ``Token`` instance is used to store information related to a user's tokens, in particular the ``Token/accessToken``, which is used to perform authenticated requests. This class conforms to Codable, so it can be persisted across app launches to keep your user signed in. But this can be cumbersome to use on a day-to-day basis, so to simplify your development workflow, the ``Credential`` class exists.

Instances of ``Credential`` not only contain a reference to that user's ``Credential/token``, but exposes convenience methods and properties to simplify common operations, such as ``Credential/refresh()``, ``Credential/userInfo()``, or ``Credential/revoke(type:)``. To ensure these operations can function, a ``Credential/oauth2`` client is automatically created on your behalf, which can be used to perform other operations as needed.

## Storing a token

When you first receive a ``Token``, you can use the ``Credential/store(token:tags:)`` static function to save the token in local storage. This function lets you supply optional tags to assign to the token, to simplify the process of retrieving those credentials at a later date.

An additional function ``Credential/with(token:)`` will return a credential object based on the given token. If that token hasn't yet been stored, it will be automatically stored for you. If this method is called multiple times with the same token, the same shared Credential instance will be returned.

## Working with the default credential

Once your user signs in, you as an application developer will want to do something with that user's credentials. While you can retain the credential object, and can pass it around throughout your application, it is often convenient to have singleton access to this common object.

The ``Credential/default`` static property does just that, providing common access to the default credential for the application. This value will additionally be persisted across app launches, ensuring you can quickly and conveniently determine if a sign in screen needs to be presented, or if a user is already present.

As a convenience, if no other tokens are present in your application, the first ``Token`` stored (either through ``Credential/store(token:tags:)`` or ``Credential/with(token:)``) will automatically be assigned as the default.

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

## Managing multiple credentials

Changing the ``Credential/default`` property doesn't remove the old value from storage. Instead, all credentials that are stored are available. This can enable multiple user credentials to be used simultaneously.

### Working with multiple credentials

Several approachs to finding and using credentials are provided, depending upon your application use-case. These facilities simplifies the process of assigning different credentials to different tasks within your application.

#### Finding credentials by ID

All tokens are automatically assigned a unique ID it can be identified by. This can be seen in the ``Token/id`` (as well as through the ``Credential/id`` property). This identifier may be used with the ``Credential/with(id:)`` function.

```swift
if let credential = try Credential.with(id: serviceTokenId) {
    // Do something with the credential
}
```

#### Finding credentials by developer-assigned tags

When storing tokens, the ``Credential/store(token:tags:)`` function accepts an optional collection of tags you can use to identify the purpose of different tokens.  The ``Credential/find(where:)`` function allows you to query tokens based on those tags at a later date.  Furthermore, those tags can later be updated by changing the credential's ``Credential/tags`` property.

```swift
try Credential.store(token: newToken, tags: ["service": "purchase"])

// Later ...

if let credential = try Credential.find(where: { $0.tags["service"] == "purchase" }).first {
    // Use the credential
}
```

#### Finding credentials by ID Token claims

If a token contains a valid ``Token/idToken``, the claims it represents are available within the ``Credential/find(where:)`` expression. The object returned within that expression supports the ``HasClaims`` protocol, meaning its values can be queried within that filter.

```swift
let userCredentials = try Credential.find { metadata in
    metadata.subject == "jane.doe@example.com"
}
```

### Removing a credential

To clean up credentials that are no longer needed, the ``Credential/remove()`` method removes the token from storage, and removes the Credential instance from ``Credential/allCredentials``.
