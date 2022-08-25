# Shared Sample Resources

The `Shared` folder contains code, storyboards, property lists, and configuration files that are used by many of the sample applications.

> **IMPORTANT:**
> The samples include file paths that reference the files in this folder.

There are different types of content:

- **Common:** A folder that contains code and storyboards.
- **Okta.plist:** A property list that contains the configuration for the Okta org Application Integration that's used by the app.
- **TestConfiguration.xcconfig:** A file that defines the configuration for the Okta org Application Integration used that's used for testing.

## Common Folder

The contents of the folders are:

- **Keychain:** Convenience extensions to Keychain for tokens.
- **Testing:** Extensions to XCTest and other classes used for testing the sample apps.
- **View Controllers:** A view controller that displays the information for a user after they've signed in.

## Okta Property List

Update the values for the keys in the file to configure the connection to your Okta Org Application Integration for your app.

 Key | Required | Description |
 ---|---|---
`issuer` | ✔ | The domain of your registered Okta org followed by `/oauth2/default`, such as `https://dev-1234567.okta.com/oauth2/default`.
`clientId` | ✔ | The client ID from the Application Integration in the Okta Admin console, such as `0ux3rutxocxFX9xyz3t9`.
`scopes` | ✔ | A space-delimited list of the permissions, or OAuth scopes requested by the client. The existing list may not need updating.
`redirectUri` | ✔  | Redirect URI for the Okta application, such as `com.okta.1234567:/callback`.
`logoutRedirectUri` | | Logout URI used for the Okta application, such as `com.okta.1234567:/logout`

Any other keys and values that you add to the plist are passed to the `additionalParameters` argument of the initializer.

> **NOTE:** You can edit this file in any of the sample app projects. Editing the file in one sample changes it for all samples.

## TestConfiguration File

Update the for the constants in the file to configure the connection to your Okta Org Application Integration for your tests.

 Constant | Description |
 ---|---
E2E_CLIENT_ID  | The client ID from the Application Integration in the Okta Admin console, such as `0ux3rutxocxFX9xyz3t9`.
E2E_DOMAIN | The domain portion of your registered Okta org.
E2E_PASSWORD | The password for the test user.
E2E_SCOPES | A space-delimited list of the permissions, or OAuth scopes requested by the client. The existing list may not need updating.
E2E_USERNAME | The username for the test user.

> **NOTE:** You can edit this file in any of the sample app projects. Editing the file in one sample changes it for all samples.
