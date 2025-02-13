# ``AuthFoundation/Credential``

## Storing Credentials

The Credential class fundamentally is used as a convenience to simplify access and storage of ``Token``s. Regardless of how the token is created, it can be securely stored by using ``store(_:tags:security:)``. This saves the token for later use.

For example, to store a token with custom tags and security options:

```swift
try Credential.store(token,
                     tags: ["displayName": "My User"],
                     security: [
                         .accessibility(.afterFirstUnlock),
                         .accessControl(.biometryAny),
                         .accessGroup("com.example.myApp.shared")
                     ])
```

For more information about the security options available, please see the ``Credential/Security`` enum.

## Retrieving Credentials

There are several ways to retrieve credentials from storage, namely the ``default`` static property, ``with(id:prompt:authenticationContext:)``, or the ``find(where:prompt:authenticationContext:)`` methods.

For more information, please refer to the <doc:ManagingUserCredentials> article.

## Notifications

Several notifications are broadcast throughout the lifecycle of Credentials which can assist developers in responding to changes.

- `.defaultCredentialChanged` -- Broadcast when the ``default`` credential is changed. The notification's object will be the Credential in question, or `nil` if the default credential is removed.
- `.credentialCreated` -- Sent when a credential is created by the ``CredentialDataSource``.  Note that this will not be sent when you use the designated initializer directly.
- `.credentialRemoved` -- Sent when a credential is removed from storage.
- `.credentialMigrated` -- Sent when a credential has been migrated from the legacy OktaOidc SDK.

## Customization

There are several ways developers can customize storage and creation of Credential instances.

### Customizing Token Storage

On Apple platforms (such as iOS, macOS, tvOS, and watchOS) the default storage mechanism is to use the Keychain to securely store tokens. In the event a developer wishes to customize how these tokens are stored, you can create your own storage object to handle the underlying operations used by the Credential class.

To override this behavior, you can create a class that conforms to the ``TokenStorage`` protocol, and assign that to the ``tokenStorage`` static property.

> Important: If you are customizing token storage, this property should be assigned before any other interactions are made to the Credential class. Changing this property at any other time is not supported, and may result in undefined behavior.

### Customizing Credential Creation

Credential instances are automatically constructed and cached at runtime when they are stored or retrieved. For example, ``store(_:tags:security:)`` returns a Credential object, and when one is retrieved using ``find(where:prompt:authenticationContext:)`` or ``with(id:prompt:authenticationContext:)``, the initializer is called on your behalf.

The behavior for how a credential is created, and what options are supplied to its initializer, is handled by the ``CredentialDataSource`` protocol. A default implementation is provided for you, but if you wish to customize the creation of these objects, you can create your own implementation and assign it to the ``credentialDataSource`` static property.

## Topics

### Storage, Retrieval, and Removal

- ``default``
- ``allIDs``
- ``store(_:tags:security:)``
- ``with(id:prompt:authenticationContext:)``
- ``find(where:prompt:authenticationContext:)``
- ``tags``
- ``setTags(_:)``
- ``remove()``
- ``id``

### Refreshing and Revoking Tokens

- ``refresh(completion:)``
- ``refresh()``
- ``refreshIfNeeded(graceInterval:)``
- ``refreshIfNeeded(graceInterval:completion:)``
- ``refreshGraceInterval``
- ``automaticRefresh``
- ``revoke(type:)``
- ``revoke(type:completion:)``

### Using Tokens

- ``token``
- ``oauth2``
- ``authorize(_:)``
- ``authorize(request:)``

### Getting Information About Tokens

- ``userInfo``
- ``userInfo()``
- ``userInfo(completion:)``
- ``introspect(_:completion:)``

### Customization

- ``credentialDataSource``
- ``tokenStorage``
