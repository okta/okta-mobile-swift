# Embedded Auth with SDKs

## Introduction
> :grey_exclamation: The use of this Sample uses an SDK that requires usage of the Okta Identity Engine. 
This functionality is in general availability but is being gradually rolled out to customers. If you want
to request to gain access to the Okta Identity Engine, please reach out to your account manager. If you 
do not have an account manager, please reach out to oie@okta.com for more information.

This Sample Application will show you the best practices for integrating Authentication into your app
using [Okta's Identity Engine](https://developer.okta.com/docs/concepts/ie-intro/). Specifically, this 
application will cover some basic needed use cases to get you up and running quickly with Okta.
These Examples are:
1. Sign In
2. Sign Out
3. Sign Up
4. Sign In/Sign Up with Social Identity Providers
5. Sign In with Multifactor Authentication using Email or Phone

## Installation & Running The App

1. Open the `okta-idx.xcworkspace` workspace from the root level in Xcode. 
2. Select the `EmbeddedAuth` application target, and choose a simulator type to use.
3. *(Optional)* Open the `Okta.plist` file, and configure it with the settings from your org.
4. Click the "Run" to launch the application in the iOS simulator.
5. *(Optional)* If you didn't configure your org settings in step 3, you can instead input your org settings within the initial launch screen (you can re-configure these settings later by tapping the `Configure` navigation bar button item).
6. Tap the "Sign In" button to start the authentication flow.

## Design Patterns

This sample application is built in such a way that it will adapt to policy changes defined within your org. There is no predetermined flow set forth in the sample application.

Key areas to focus on are:

* `Signin.swift` – This class is used to orchestrate the authentication workflow, and to identify which view controller is approprioate to handle responses.
* `SigninCoordinator.swift` – A shared singleton that hooks into the UIWindowScene to present an onboarding window to display a landing page when the app is not logged in. This also hosts a navigation controller used to handle the login process.
* `FormRows.swift` – This file holds several extensions to IDX classes that adapts the server responses to a set of very simple view models, that describe the layout of user-facing views.
* `IDXRemediationTableViewController.swift` – This view controller manages the bulk of UI states, and dynamically populates a table view with cells, based on the remediation options and form fields returned from the server.
* `IDXSignin.storyboard` – A storyboard that hosts the prototype cells used to render the UI.
