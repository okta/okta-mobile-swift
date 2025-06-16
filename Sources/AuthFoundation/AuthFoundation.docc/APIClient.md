# ``AuthFoundation/APIClient``

## Subclassing Notes

Many features of the APIClient protocol have default implementations that should serve most purposes, but there are some methods that either must be implemented in concrete instances of APIClient, or may need to be customized for special behavior.

### Methods to override

* Delegates - When working with delegates or delegate collections, the following methods should be implemented:
  * ``willSend(request:)-9lrtd`` - This is invoked immediately prior to a request being sent to URLSession.
  * ``didSend(request:received:)-42ak`` - This is invoked when a successful response is received from a request.
  * ``didSend(request:received:requestId:rateLimit:)`` - This is invoked when an error is returned from a request.
* Error parsing - Some API clients may have custom response error types; if your API includes custom error messages in HTTP response bodies, the following should be overridden:
  * ``error(from:)-701g0``
