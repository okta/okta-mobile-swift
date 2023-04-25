# Samples

These samples show you how to add different ways to sign-in a user, called authentication workflows to your app. Each sample shows code for both implementing and testing the workflow.

## Using the Samples

These samples are designed to be built and run from the `OktaMobileSDK` workspace. To use them outside of the workspace:

1. Copy the sample folder to the desired location.
2. Copy the `Shared` folder to the same location at the same level as the sample folder.
3. Open the sample project in Xcode.
4. Select the project and add the Okta Swift Mobile SDK Swift Package.

Sample | Summary |
 ---|---
[ClassicNativeAuth Sample](ClassicNativeAuth) | Use the Okta Mobile SDK for Swift to add native authentication to your app that uses the classic OktaAuthSdk.
[DeviceAuthSignIn Samples](DeviceAuthSignIn) | Add sign-in using the OAuth 2.0 device authorization grant flow to your tvOS app.
[OIDCMigration Sample](OIDCMigration) | Migrate your app to the new Okta Mobile SDK for Swift from legacy SDKs.
[UserPasswordSignIn Samples](UserPasswordSignIn) | Add sign-in with a username and password to a macOS app.
[WebSignIn Samples](WebSignIn) | Add web-based sign in and single sign-on that uses the token exchange flow from the OAuth 2.0 specification with the WebAuthenticationUI Library.
[DirectAuthSignIn Samples](DirectAuthSignIn) | Add native sign-in and sign out that uses the Okta Direct Authentication API (EA) using the OktaDirectAuth library.
