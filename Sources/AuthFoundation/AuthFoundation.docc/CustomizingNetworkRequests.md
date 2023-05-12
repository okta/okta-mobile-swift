# Customizing Network Requests

Manage or monitor network requests sent by the Okta Mobile SDK.

## Overview

There are many circumstances in which you may want to monitor, or alter, network requests as they are sent from within the SDK. There are several facilities built into AuthFoundation and its associated libraries that enables developers to interact with the network in a flexible manner.

All network interactions within these SDKs are built around the ``APIClient`` protocol. For example, the ``OAuth2Client`` itself implements the ``APIClient`` protocol. As a result, each client instance conforms to these same capabilities, which means they each support the use of the ``APIClientDelegate``.

## Using APIClientDelegate to monitor network operations

For more information about this delegate protocol, see the ``APIClientDelegate`` protocol definition for its specific uses. 

### Modifying outgoing network requests

If your application needs to monitor outgoing network requests, the ``APIClientDelegate/api(client:willSend:)-9cnzq`` method can be used to observe when network requests will be sent.

More importantly, the `URLRequest` argument supplied to this delegate method is supplied as an `inout` value. This allows you to not only observe which requests are being made (e.g. to allow analytics or logging to be used), but they can be altered before being sent over the network.

As an example, here's how you might be able to add your own outgoing HTTP request headers.

```swift
extension MyClass: APIClientDelegate {
    func api(client: APIClient, willSend request: inout URLRequest) {
        request.addValue("CustomValue", forHTTPHeaderField: "x-My-Header")
    }
}
```

When you add your delegate (e.g. using ``OAuth2Client/add(delegate:)``), your class can then intercept these messages and monitor, or alter, outgoing requests.

### Monitoring outgoing network requests

Building upon the previous section, another method ``APIClientDelegate`` supports is handling responses to requests, through the use of ``APIClientDelegate/api(client:didSend:received:)-4mcbm``. Information about the raw response, including ``APIResponse/RateLimit``, associated links (e.g. next, previous, and current pagination results), and information about the request ID (which can be used for debugging purposes).
