# Introduction to Authentication Flows

Create custom sign in experiences using OAuth2 authentication flows.

## Overview

Authenticating using a web browser and the `WebAuthenticationUI` library is quick and easy, but there are times when you need to craft more custom sign in experiences. For example, you may want to sign a user in across multiple applications, or enable users to sign in on a tvOS application. These advanced use-cases are supported through a variety of authentication flows.

If you wish to have more control over the authentication process, you may wish to look into using an authentication flow directly.

## What are Authentication Flows?

Authentication Flows are classes that encapsulate the lifecycle of authenticating with a particular flow. For example, implementing the [Device Authorization Grant Flow](https://developer.okta.com/docs/guides/device-authorization-grant/main/) can be complex, particularly since it involves polling against the authorization server, which can increase the burden on you to get the details right.

By leveraging an authentication flow, you can focus on your UI, leaving the technical details to the Okta SDK.

These separate flows are built in such a way that they follow a similar pattern, making it easier to understand how to use the flow.

## Typical Authenticator Workflow

Most authenticators follow a typical pattern involving similarly-named functions: `start` and `resume`. Optionally the `reset` function can be used to reset a flow.

![Flowchart describing typical authenticator flow.](AuthenticatorFlowsWorkflow)

### Single-Step Flows

A simple authenticator, such as ``ResourceOwnerFlow``, is a single-step flow which completes in one operation:

```swift
let flow = ResourceOwnerFlow(
    issuerURL: URL(string: "https://example.okta.com")!,
    clientId: "abc123client",
    scope: "openid offline_access email profile")

let token = try await flow.start(
    username: "smeagol",
    password: "myprecious")
```

### Two-Step Flows

More complicated authenticators require some context or state to be provided to the `resume` function. In the case of ``AuthorizationCodeFlow`` the redirect URI returned from the authorization server is provided to ``AuthorizationCodeFlow/resume(with:)``, while the ``DeviceAuthorizationFlow`` uses a context object returned from the ``DeviceAuthorizationFlow/start()`` function.

```swift
let flow = DeviceAuthorizationFlow(
    issuerURL: URL(string: "https://example.okta.com")!,
    clientId: "abc123client",
    scope: "openid offline_access email profile")

// Retrieve the context for this session.
let context = try await flow.start()

// Present information from the context to the user.
// Once that is done, use the following code to
// poll the server to retrieve a token when they
// authorize the code.
let token = try await flow.resume()
```

### Multi-Step Flows

`InteractionCodeFlow` (implemented in the `OktaIdx` library) supports a many-step workflow, that adapts to user choices and server-driven policy settings. This workflow, while fundamentally simliar, has many more steps that guides a user through authentication. For more information, please see the documentation for that library.

## Using Delegation

All authorization flows support the use of a delegate, which enables parts of your application to interact with the flow in a variety of ways. For example, your application could update UI state to reflect a progress indicator when authorization starts, or could present an error automatically in response to a failure.

Some delegates, such as ``AuthorizationCodeFlowDelegate``, supports customizing the workflow through the use of a delegate. See the ``AuthorizationCodeFlowDelegate/authentication(flow:shouldAuthenticateUsing:)-9ux29`` or ``AuthorizationCodeFlowDelegate/authentication(flow:customizeUrl:)-9f4xy`` functions for more details.

Additionally, convenience libraries such as `WebAuthenticationUI` provides access to the underlying flow, giving convenient access to customizing the flow for your own application's needs. For more information, please see the documentation for that library.
