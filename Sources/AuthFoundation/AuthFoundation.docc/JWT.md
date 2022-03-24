# ``AuthFoundation/JWT``

A JWT object represents information encoded within a JSON Web Token, a base64-encoded JSON object that contains a header, a payload, and a signature that is used to verify the validity of the token itself. The contents of the payload, referred to as "Claims", can then be read within your application.

These objects conform to both the ``HasClaims`` and ``Expires`` protocols, to provide conveniences for accessing information within the token, as well as to determine whether or not the token has expired.  In addition to accessing arbitrary claims within a token, this class adds conveniences to simplify access to, and to normalize the expected result types of, properties common to JWT tokens.

## Accessing claims

Reading information, or "Claims", from a JWT token can be done in three different ways:

1. Accessing values using convenience properties
2. Using keyed subscripting of common claims using the ``Claim`` enum
3. Using keyed subscripting of custom claims using the claim's string name.

Some common properties, such as ``HasClaims/subject`` or ``issuer``, are defined as properties on the JWT object, to simplify access to these values. Additionally, some claims that return dates or time intervals have conveniences such as ``issuedAt``, ``expirationTime``, ``expiresIn``, or ``scope``, that returns their values in the expected type.

When you wish to interact with other claims more dynamically, the ``HasClaims/claims`` or ``HasClaims/customClaims`` properties can be used to identify which claims are present in the JWT token.

For example, to access or interact with the predetermine claims:

```swift
for claim in token.claims {
    let value = token[claim] // Use the claim
}
```

If you anticipate specific claims within your application, you can interact with them directly.  For example:

```swift
if let email = token[.email] {
    // Do something with the token's email address
}

if let customValue = token["customClaim"] {
    // Use the custom value
}
```
