# Samples

## WebSignIn (iOS)

This sample demonstrates web authentication using the WebAuthenticationUI library.  To get started, open the `Okta.plist` file and update its contents with your application's configuration settings to run the sample.

## SingleSignOn (iOS)

This application demonstrates Device SSO authentication (also referred to as `TokenExchangeFlow` within OktaOAuth2). This sample works in conjuction with the WebSignIn (iOS) sample. 

Configure the client by opening the `SingleSignOnViewController.swift` file, and input the client's settings.

If the `Okta.plist` file (from the WebSignIn sample) is configured with the `device_sso` scope, the device secret that is created when authenticating using the web sign in sample is saved to a common keychain entry within a shared App Group.

After signing in, launch the SingleSignOn demo application, and your user should be logged in automatically.

## WebSignIn (macOS)

This is a counterpart to the iOS web sign in sample, and demonstrates a simple macOS SwiftUI application, authenticating over the web.  This application's `Okta.plist` file is shared with the iOS application.

## DeviceAuthSignIn (tvOS)

This sample demonstrates the Device Code Flow (referred to as `DeviceAuthorizationFlow` within OktaOAuth2), and how this can be used to sign in to a tvOS application.

To configure the sample, open the `ViewController.swift` file, and configure the flow with your application's settings.

## UserPasswordSignIn (macOS)

This sample demonstrates the `ResourceOwnerFlow`, which allows users to sign in with a simple username and password. This is a macOS command-line application, and uses command-line arguments to supply client settings.

Simply build the application and, finding the path to the executable within your `DerivedData` folder, and execute the command from the command-line.  Alternatively, you can edit the `UserPasswordSignIn (macOS)` scheme to add arguments, which will enable you to run the sample from within the Xcode debug environment.
