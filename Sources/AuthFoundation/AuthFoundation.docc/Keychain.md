# ``AuthFoundation/Keychain``

## Creating Keychain Items

The ``Keychain/Item`` struct represents individual items in the keychain. It can be used to create new items, and is returned as a result when getting an existing item.

```swift
let data = "My Secret".data(using: .utf8)
let item = Keychain.Item(account: "userId",
                         service: "com.example.myService",
                         accessibility: .afterFirstUnlockThisDeviceOnly,
                         value: data!)
let savedItem = try item.save()
```

## Getting an Individual Keychain Item

When you know the exact account you would like to retrieve, you can perform a search to get an individual ``Keychain/Item``. To do this, you use the ``Keychain/Search/get(prompt:authenticationContext:)`` method.

```swift
let search = Keychain.Search(account: "userId",
                             service: "com.example.myService")
let item = try search.get()
```

## Searching for Keychain Items

When you need to get a list of keychain items, you can use the ``Keychain/Search/list()`` method to get a list of results. The items in this search do not request the secret data stored within the items, meaning it should be safe to perform without triggering biometric prompts or encountering other accessibility restrictions.

```swift
let search = Keychain.Search(account: "userId",
                             service: "com.example.myService")
for result in try search.list() {
    // Do something with the result
}
```

The ``Keychain/Search/Result`` type represents individual results. This contains the public information for each item.

## Deleting Keychain Items

You can delete individual keychain items from either a ``Keychain/Item`` or ``Keychain/Search/Result`` instance. 

For example, to delete an item:

```swift
let search = Keychain.Search(account: "userId",
                             service: "com.example.myService")
let item = try search.get()
try item.delete()
```

Or when you have an individual search result, you can perform a deletion at that time.

```swift
let search = Keychain.Search(account: "userId",
                             service: "com.example.myService")
if let result = try search.list().first {
    try result.delete()
}
```

If you wish to delete multiple items, you can perform a delete on the Search itself. For example, to delete all items within a given service:

```swift
try Keychain.Search(service: "com.example.myService").delete()
```

## Updating Keychain Items

Several objects also support the ability to be updated, for example ``Keychain/Item/update(_:authenticationContext:)`` and ``Keychain/Search/Result/update(_:authenticationContext:)``.  To do this, you supply a new ``Keychain/Item`` to be used when updating and replacing the old item.

```swift
let oldItem = Keychain.Search(account: "userId",
                              service: "com.example.myService").get()
let newItem = Keychain.Item(account: "userId",
                            service: "com.example.myService",
                            value: "New Value".data(using: .utf8)!)
try oldItem.update(newItem)
```

## Working with Keychain Accessibility and Access Control

One of the more complex parts of using the keychain is controlling keychain accessibility, defining access control, and working with Local Authentication contexts.

To simplify this process, the ``Keychain/Accessibility`` enum is provided to simplify how accessibility is defined.  This can be used when creating a new ``Keychain/Item`` as well as when updating a keychain item (for example, to change the keychain accessibility of an existing item).

```swift
let data = "My Secret".data(using: .utf8)
let item = Keychain.Item(account: "userId",
                         accessibility: .afterFirstUnlockThisDeviceOnly,
                         value: data!)
let savedItem = try item.save()
```

In a similar fashion, you can pass a `SecAccessControl` instance when saving an item, to define custom access settings such as biometric, user presence, etc.

## Biometric Prompts and Authentication Context

Many operations, such as ``Keychain/Search/get(prompt:authenticationContext:)``, ``Keychain/Search/Result/get(prompt:authenticationContext:)``, or ``Keychain/Search/Result/update(_:authenticationContext:)``, can accept either a user-facing message, and an authentication context, that can be used to help with prompting the user for biometric access.  The prompt is used when asking the user for FaceID or TouchID access, to explain to the user why they need to provide access.

The authentication context, from the LocalAuthentication framework, can additionally be supplied to further provide controls over how and when biometric propts are provided to the user.
