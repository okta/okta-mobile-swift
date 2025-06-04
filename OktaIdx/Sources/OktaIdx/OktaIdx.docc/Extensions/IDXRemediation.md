# ``OktaIdx/Remediation``

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

All authentication scenarios, whether they are simple or complex, consist of a series of steps that may be followed, but at some times the user may have a choice in what they use to verify their identity. For example, a user may have multiple choices in verifying their account, such as:

1. Password
1. Security Questions
1. Email verification
1. Other, customizable, verification steps.

A remediation represents an individual choice a user can make. Each remedation includes details about what form values should be used to collect information from the user, and a description of the resulting request that should be sent to Okta to proceed to the next step.

Nested form values can be accessed through keyed subscripting, for example:

```swift
response.remediations[.identifier]
```

Remediations may contain ``capabilities`` which defines additional behaviors or operations that may be performed for some options.
