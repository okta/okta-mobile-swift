# Introduction to Authentication Flows

Create custom sign in experiences using OAuth2 authentication flows.

## Overview

Authenticating using a web browser and the `WebAuthenticationUI` library is quick and easy, but there are times when you need to craft more custom sign in experiences. For example, you may want to sign a user in across multiple applications, or enable users to sign in on a tvOS application. These advanced use-cases are supported through a variety of authentication flows.

If you wish to have more control over the authentication process, you may wish to look into using an authentication flow directly.

## What are Authentication Flows?

Authentication Flows are classes that encapsulate the lifecycle of authenticating with a particular flow. For example, implementing the [Device Authorization Grant Flow](https://developer.okta.com/docs/guides/device-authorization-grant/main/) can be complex, particularly since it involves polling against the authorization server, which can increase the burden on you to get the details right.

By leveraging an authentication flow, you can focus on your UI, leaving the technical details to the Okta SDK.

These separate flows are built in such a way that they follow a similar pattern, making it easier to understand how to use the flow.

## 
