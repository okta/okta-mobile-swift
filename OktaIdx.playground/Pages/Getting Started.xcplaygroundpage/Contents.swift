/*:
 # Table of Contents
 
 * [Getting started using Okta Identity Engine](Getting%20Started)
 * [Get new tokens using passcode](Passcode%20Login)
 * [Remediation / MFA with Okta sign-on policy](Remediation%20-%20MFA-SOP)

 ## Overview
 
 This playground provides a step-by-step introduction for the Okta Identity Engine SDK for Swift (OktaIdx). Much of the SDK is asynchronous and metadata-driven, which means the way the SDK is used may depend on the configuration of your client application.
 
 For the purposes of this tutorial, it might be beneficial to set up a sample application to follow along.
 
 - Important:
 In these samples, a special `PlaygroundHelper` class is used to collapse the asynchronous calls into a flat series of calls. This makes the process easier to follow in this playground. This uses a similar approach to `XCTestCase` in the use of expectations, though this isn't advisable to use in production applications.\
 \
 Additionally, when secure information is needed (such as username, pasword, email verification code, etc), these will use the `helper.showPrompt()` call, which will present a Live View in the Playground.
 
 ## Creating a sample application
 
 <Instructions for creating an app>
 
 ## Configuring the SDK
 
 Once you have the client configuration details from the Okta dashboard, you can enter those details here.
 
 ## Prompting for user data
 
 Some remediation flows require information to be entered at runtime, such as usernames, passwords, and email verification codes. To suppor this, the Playground uses the Live View area to prompt you, the developer, for those values.
 
 ![Username prompt preview](UsernameSelectionScreenshot.png "Sample username prompt")
 */
 
import OktaIdx

let config = IDXClient.Configuration(issuer: "https://some-name.okta.com/oauth2/default",
                                     clientId: "my-client-id",
                                     clientSecret: nil,
                                     scopes: ["openid", "email"],
                                     redirectUri: "my-app://redirect")

/*:
 After the configuration is created, you supply that to the constructor for `IDXClient`, at which point you can begin the authentication process.
 */

let client = IDXClient(configuration: config)

/*:
 With the client object in hand, you can continue to the next step, which is starting the workflow.
 */

//: [Next](@next)
