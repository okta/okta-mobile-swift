# Managing User Credentials

Store, retrieve, and change user credentials within your application.

## Overview

The primary goal of using authentication APIs is to ultimately receive credentials for your users, allowing your them to do something with your application. If you don't have some way to save and retrieve those credentials for later use, your users would need to sign into your application every time they opened it.

Since no two applications are alike, and usage patterns vary wildly, Okta's AuthFoundation library exposes several features that enable you to access and manage user credentials conveniently, while still affording you the ability to customize behavior to suit your needs.

## Introduction to the User class

Within AuthFoundation a ``Token`` instance is used to store information related to a user's credentials, in particular the ``Token/accessToken``, which is used to perform authenticated requests. This class conforms to Codable, so it can be persisted across app launches to keep your user signed in. But this can be cumbersome to use on a day-to-day basis, so to simplify your development workflow, the ``User`` class exists.

Instances of ``User`` not only contain a reference to that user's ``User/token``, but exposes convenience methods and properties to simplify common operations, such as ``User/refresh()``, ``User/userInfo()``, or ``User/revoke(type:)``. To ensure these operations can function, a ``User/oauth2`` client is automatically created on your behalf, which can be used to perform other operations as needed.

## Creating a new user

When your application receives a new ``Token``, convenience methods are provided to simplify the process of creating new ``User`` instances, or to retrieve a previously-created instance.

The ``User/for(token:)`` static method coordinates the loading and creation of a user object for the supplied token.  If this method is called multiple times with the same token, the same shared User instance will be returned.

## Working with the default user

Once your user signs in, you as an application developer will want to do something with that user's credentials. While you can retain the user object, and can pass it around throughout your application, it is often convenient to have singleton access to this common object.

The ``User/default`` static property does just that, providing common access to the default user. This value will additionally be persisted across app launches, ensuring you can quickly and conveniently determine if a sign in screen needs to be presented, or if a user is already present.

As a convenience, if the ``User/for(token:)`` method is used, and no other user is already present in your application, it will automatically be assigned as the default user.

### Changing the default user

If at some point you would like to change the default user, or sign in a new user, you can simply set a new value to this property, and the value will be persisted for the next application launch.

One challenge in applications is responding to change, particularly when transitioning between signed-out and -in. To that end, a NotificationCenter notification is broadcast whenever the default user changes.

```swift
NotificationCenter.default.addObserver(forName: .defaultUserChanged,
                                       object: nil,
                                       queue: .main) { notification in
    guard let user = notification.object as? User else {
        // User signed out
        return
    }
    
    // Do something with the user
}
```

## Managing multiple users

Changing the ``User/default`` user property doesn't remove the old value from storage. Instead, all users that are stored are available through the ``User/allUsers`` property. This can enable multiple user credentials to be used simultaneously.

### Removing a user

To clean up users that are no longer needed, the ``User/remove()`` method removes the token from storage, and removes the User instance from ``User/allUsers``.
