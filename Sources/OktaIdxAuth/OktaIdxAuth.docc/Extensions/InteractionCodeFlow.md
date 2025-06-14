# ``OktaIdxAuth/InteractionCodeFlow``

## Topics

### Essentials

- ``init()``
- ``init(plist:)``
- ``init(client:additionalParameters:)``
- ``init(issuerURL:clientId:scope:redirectUri:additionalParameters:)``
- ``start(with:)``
- ``resume()``
- ``resume(with:)->Response``
- ``resume(with:)->InteractionCodeFlow.RedirectResult``
- ``resume(with:)->Token``

### Completion Block Functions

- ``start(with:completion:)``
- ``resume(completion:)``
- ``resume(with:completion:)-(Response,_)``
- ``resume(with:completion:)-(URL,_)``
- ``resume(with:completion:)-(Remediation,_)``
