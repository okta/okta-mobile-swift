# ``Capability``

Abstractly describes the types of operations, metadata, or additional information that can be associated with IDX remediations or authenticators.

IDX is inherently extensible and is highly metadata-driven. Some authenticators or remediations can have additional information or actions associated with them, depending on the type involved. To simplify how you interact with these objects, these are decomposed into a set of Capability objects that describes their function.

## Available capabilities

At its core, there are two primary types of capabilities: ``Authenticator/CapabilityType`` and ``Remediation/CapabilityType``.  The full list of capabilities can be retrieved using the ``CapabilityCollection/capabilities`` property, or convenience functions are provided to return the appropriate values as an Optional. 

### Authenticator Capabilities

| Capability Type | Convenience Property | Description |
| --------------- | -------------------- | ----------- |
| ``NumberChallengeCapability`` | ``Authenticator/numberChallenge`` | Represents a User Verification (UV) number challenge, for example within a Okta Verify push notificatio challenge. |
| ``PasswordSettingsCapability`` | ``Authenticator/passwordSettings`` | Provides details on the password complexity settings required. |
| ``PollCapability`` | ``Authenticator/pollable`` | Allows the client to poll the authenticator when an out-of-band challenge is underway. |
| ``ProfileCapability`` | ``Authenticator/profile`` | Provides additional profile information related to the authenticator. |
| ``RecoverCapability`` | ``Authenticator/recoverable`` | Enables the user can begin a recovery process for this authenticator. |
| ``SendCapability`` | ``Authenticator/sendable`` | Represents an action the user can perform to send an out-of-band challenge or request using this authenticator. |
| ``ResendCapability`` | ``Authenticator/resendable`` | Allows an authenticator to resend an out-of-band challenge using this authenticator. |
| ``OTPCapability`` | ``Authenticator/otp`` | Provides details about authenticators that provide a time-based one-time-password. |

### Remediation Capabilities

| Capability Type | Convenience Property | Description |
| --------------- | -------------------- | ----------- |
| ``PollCapability`` | ``Remediation/pollable`` | Allows the client to poll a remediation when the user has begun an out-of-band challenge. |
| ``SocialIDPCapability`` | ``Remediation/socialIdp`` | Provides additional information required when a user selects an authentication using a Social IDP. |

## How capabilities work

The ``Capability`` protocol is used by a class or struct to represent actions or information available on an object that conforms to ``CapabilityCollection``, which then references an enum that implements the ``IsCapabilityType`` protocol.

Both ``Authenticator`` and ``Remediation`` act as a ``CapabilityCollection``, defining their list of capabilities with the ``Authenticator/CapabilityType`` and ``Remediation/CapabilityType`` enumerations respectively.



