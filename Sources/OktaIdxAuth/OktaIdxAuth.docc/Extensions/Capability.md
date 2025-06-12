# ``OktaIdx/Capability``

Abstractly describes the types of operations, metadata, or additional information that can be associated with IDX remediations or authenticators.

IDX is inherently extensible and is highly metadata-driven. Some authenticators or remediations can have additional information or actions associated with them, depending on the type involved. To simplify how you interact with these objects, these are decomposed into a set of Capability objects that describes their function.

## Types of Capabilities

At its core, there are two primary types of capabilities: ``AuthenticatorCapability`` and ``RemediationCapability``. The former are capabilities exclusively associated with ``Authenticator`` instances, while the latter is associated with ``Remediation`` instances. Some capabilities can be used in both, which means in those cases the underlying capability may conform to both protocols.

### Authenticator Capabilities

- ``NumberChallenge``
- ``PasswordSettings``
- ``Pollable``
- ``Profile``
- ``Recoverable``
- ``Sendable``
- ``Resendable``
- ``OTP``

### Remediation Capabilities

- ``Pollable``
- ``SocialIDP``
