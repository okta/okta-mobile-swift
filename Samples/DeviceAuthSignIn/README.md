# DeviceAuthSignIn

This sample contains two separate sample application schemes:

## DeviceAuthSignIn (tvOS)

This sample demonstrates the Device Code Flow (referred to as `DeviceAuthorizationFlow` within OktaOAuth2), and how this can be used to sign in to a tvOS application.

To configure the sample, open the `ViewController.swift` file, and configure the flow with your application's settings.

## DeviceAuthSignIn (iOS)

Similar to the `DeviceAuthSignIn (tvOS)` application, this sample demonstrates the flow within an iOS application, solely for the purposes of automated testing. This is necessary since tvOS does not contain a web browser, and as such cannot support end-to-end testing the authentication process.
