# Bug: Deadlock in `SDKVersion.register` due to Main Thread Synchronization

## Summary
A deadlock occurs when initializing `SDKVersion` or calling `SDKVersion.register` from a background thread. This often happens implicitly when initializing components like `OAuth2Client`. The method holds a private lock while synchronously intercepting the Main Thread to retrieve `UIDevice` information. If the Main Thread simultaneously attempts to access `SDKVersion` (e.g., reading `userAgent`), the application deadlocks.

## Reproduction Steps

1.  **Background Initialization**: Initialize an instance of `OAuth2Client` (or other SDK components) from a background thread. In Swift < 6, unstructured `Task { }` blocks often run on a background executor.
2.  **Transitive Registration**: The `OAuth2Client` initializer implicitly accesses `SDKVersion.authFoundation`, which triggers static initialization and calls `SDKVersion.register`.
3.  **Lock Acquisition**: `register` acquires the private `SDKVersion.lock`.
4.  **Main Thread Block**: While holding the lock, the code attempts to read `UIDevice.current.systemVersion`. This forces a synchronous thread hop (`DispatchQueue.main.sync`) to the Main Thread.
5.  **Deadlock**: The background thread is now blocked waiting for the Main Thread. If the Main Thread is blocked or waiting on any resource (like the same `SDKVersion.lock`), the app deadlocks.

### Reproduction Snippet

```swift
// Background Thread initialization
// In Swift < 6, `Task { ... }` runs on the background generic executor.
// Initializing `OAuth2Client` (or other components) transitively calls `SDKVersion.register`.
// The deadlock occurs when initializing the `OAuth2Client` class itself.
```swift
// Background Thread initialization
// In Swift < 6, `Task { ... }` runs on the background generic executor.
// Initializing `OAuth2Client` (or other components) transitively calls `SDKVersion.register`.
Task {
    // Acquires lock during initialization, then performs dispatch_sync to Main Thread
    let client = OAuth2Client(issuerURL: URL(string: "https://example.com")!,
                              clientId: "clientId",
                              scope: "openid")
}
```

### Expected Output (Hang)
When the deadlock occurs, the console will show the following logs and then stop indefinitely:

```text
🏁 Starting Deadlock Reproduction
Background: Initializing OAuth2Client... (Acquiring Lock)
Main: Accessing SDKVersion.userAgent... (Requiring Lock)
```

**Note**: The success messages (`✅`) will never appear.

### Call Chain Analysis
The initialization of `OAuth2Client` triggers the deadlock through the following chain:
1. `OAuth2Client.init` call `assert(SDKVersion.authFoundation != nil)`
2. Accessing `SDKVersion.authFoundation` triggers its static initialization.
3. Static closure calls `SDKVersion.register(...)`
4. `register` holds `SDKVersion.lock` while synchronously dispatching to the Main Thread for device info.


## Affected Code

### `SDKVersion.swift`
The `register` method holds a lock before accessing `systemVersion`, which triggers the main thread sync.

```swift
// Sources/AuthFoundation/Migration/SDKVersion.swift

public static func register(sdk: SDKVersion) -> SDKVersion {
    lock.withLock { // [!] Lock acquired here
        // ...
        // [!] Accessing systemVersion triggers MainActor.nonisolatedUnsafe
        _userAgent = "\(sdkVersionString) \(systemName)/\(systemVersion) Device/\(deviceModel)" 
        return sdk
    }
}
```

### `ExpressionUtilities.swift`
The helper utility forces a synchronous wait on the Main Thread.

```swift
// Sources/CommonSupport/ExpressionUtilities.swift

public static func nonisolatedUnsafe<T: Sendable>(_ block: @MainActor () -> T) -> T {
    if Thread.isMainThread {
        return MainActor.assumeIsolated { block() }
    } else {
        return DispatchQueue.main.sync { // [!] Synchronous wait for Main Thread
            // ...
            block()
            // ...
        }
    }
}
```

## Critique & Recommendation

**Issue**: Inversion of Control / Unsafe Threading Assumption.
The `SDKVersion.register` method is designed with a critical flaw: it holds a lock while synchronously waiting for the Main Thread (`DispatchQueue.main.sync`). This implementation implicitly assumes that registration will either occur on the Main Thread or when the Main Thread is free.

However, initializing core components like `OAuth2Client` on a background thread (a common pattern for performance) triggers this registration. This creates a **deadlock trap**: the background thread holds the lock and waits for Main, while any Main Thread operation needing that lock (such as fetching `User-Agent` for headers) will hang indefinitely.

**Fix**:
Decouple the `UIDevice` access from the lock scope. Fetch the system version independently or asynchronously before acquiring the lock, or cache it safely without blocking the critical section.