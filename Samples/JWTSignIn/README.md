# JWTSignIn

## Abstract

Sign in with a signed JWT through the JWT Bearer Authorization flow.

## Overview

The command-line interface (CLI) app in the sample requires four pieces of information:

- The issuer URL for your Okta org authorization server. This is usually the domain of your registered Okta org followed by `/oauth2/default`, such as `https://example.okta.com/oauth2/default`.
- The client ID from the Okta Org Application Integration from the Okta Admin console, such as `0uxa9VpZDRCeFh3Nkk2V`.
- The permissions, or OAuth scopes that are requested by the application, such as `openid` or `profile`.
- The JWT assertion, either supplied as a command-line argument, or loaded from a file.

The JWT assertion can be supplied through a command-line argument:

```zsh
$ JWTSignIn --client-id 0uxa9VpZDRCeFh3Nkk2V \
    --issuer https://example.okta.com/oauth2/default \
    --scopes "openid profile" \
    --assertion <the_jwt>
```

Alternatively a file can be specified in a file (use a filename of `-` to read the JWT assertion from STDIN).

```zsh
$ JWTSignIn --client-id 0uxa9VpZDRCeFh3Nkk2V \
    --issuer https://example.okta.com/oauth2/default \
    --scopes "openid profile" \
    --file ./assertion.json
```

## Running the App

You can run the app from the command line, or by using the Build and Run command in Xcode and providing the command line argument values in your scheme.

To find the full path for the executable of the app:

1. Build the app in Xcode.
2. In the Project Navigator window, select `JWTSignIn` in the Products folder.
3. The full path is shown in the File Inspector.
