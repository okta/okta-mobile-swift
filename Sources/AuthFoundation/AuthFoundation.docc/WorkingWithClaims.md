# Working with Claims

Using Claims on the various types included in OIDC and AuthFoundation. 

## Overview

OpenID Connect (OIDC) uses claims to describe individual pieces of information, like email or name, packaged into responses from the server. ID Tokens in particular contain claims, packaged within a JSON Web Token (``JWT``). A variety of other OIDC capabilities also supply information using claims, such as the OpenID Configuration (``OpenIdConfiguration``) metadata returned from the server, when [introspecting a token](``Credential/introspect(_:)``).

Since claims are a common characteristic of authentication, this SDK provides features that improves the developer experience (DX) to simplify how this information is used, and to make these capabilities consistent across areas of the toolchain.

## Types that have claims

A variety of types contain claims, which are identified by types that conform to the ``HasClaims`` protocol. This protocol provides common access patterns for using claims, and conveniences for simplfying how you can access them.

Some of these types include:

* ``JWT``
* ``UserInfo``
* ``TokenInfo``
* ``OpenIdConfiguration``
* ``Token/Metadata``

To better understand how these types can be used, it's best to work with an example, starting with ``JWT``.

## Examples of using Claims

When a user signs in they are issued a ``Token/idToken`` which is returned as a JSON Web Token ``JWT``. This token contains information about the user, and other important values which could be useful to your application. For example, you may wish to retrieve the user's name and "subject" (their user identifier) to display within your interface. The ``HasClaims`` protocol makes this easy by providing several ways to extract information.

### Keyed Subscripting, using strings

If you know the string identifier for the claim, you can use that as a subscript key on the relevant object.

```swift
if let identifier = token.idToken?["sub"] {
  Text("Username: \(identifier)")
}
```

This can be useful, especially when your application uses custom claims supplied from the authorization server, but when using standard claim values, it can be more convenient to use enums.

### Keyed Subscripting, using claim enum values

Enum values are often more convenient to use since code auto-completion and compile-time warnings can ensure consistency when working with these values.

```swift
if let identifier = token.idToken?[.subject] {
  Text("Username: \(identifier)")
}
```

When working with claims, the type of enum is defined by the conforming type, which can help give you an insight into the possible options available to you. 

### Convenience properties

Finally, some common claims which are best represented as more concrete types, such as URL or Date, are provided to simplify your workflow. For example, if you want to retrieve the date the user was authenticated using ``HasClaims/authTime``, or the user's locale (in an Apple-friendly format) using ``HasClaims/userLocale``.

```swift
if let authTime = token.idToken?.authTime,
    authTime.timeIntervalSinceNow < 3600 {
  // The user authenticated more than one hour ago
}
```

### Enums and arrays of converted values

Some types conform to a special protocol called ``ClaimConvertable``, which enables concrete types to be convertable from the raw claim values supplied by the authorization server. This can make interacting with claims easier and more developer-friendly.

One example of this type is the ``HasClaims/authenticationMethods`` property. The ``JWTClaim/authMethodsReference`` claim returns an array of the methods a user used to authenticate their account. The values for this claim can be represented by the ``AuthenticationMethod`` enum, so instead of performing string comparisons, you can reference this convenience property to work with the authentication methods reference as an array of enums.

```swift
if let authenticationMethods = token.idToken?.authenticationMethods,
   authenticationMethods.contains(.multipleFactor)
{
    // The user authenticated using some multifactor step
}
```
