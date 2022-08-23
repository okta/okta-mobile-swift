# UserPasswordSignIn

## Abstract

Add sign-in with a username and password to a macOS app.

## Overview

The command-line interface (CLI) app in the sample requires five pieces of information:

- The issuer URL for your Okta org authorization server. This is usually the domain of your registered Okta org followed by `/oauth2/default`, such as `https://dev-1234567.okta.com/oauth2/default`.
- The client ID from the Okta Org Application Integration from the Okta Admin console, such as `0ux3rutxocxFX9xyz3t9`.
- The permissions, or OAuth scopes that are requested by the application, such as `openid` or `profile`.
- The username.
- The password.

You provide the first three items as command-line arguments. For example:

```zsh
$ UserPasswordSignIn --client-id 0ux3rutxocxFX9xyz3t9 --issuer https://dev-1234567.okta.com/oauth2/default --scopes "openid profile"
```

The app prompts for the username and then the password.

## Running the App

You can run the app from the command line, or by using the Build and Run command in Xcode and providing the command line argument values in your scheme.

To find the full path for the executable of the app:

1. Build the app in Xcode.
2. In the Project Navigator window, select `UserPasswordSignIn` in the Products folder.
3. The full path is shown in the File Inspector.
