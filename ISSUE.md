# `withIsolationSyncThrowing` / `withIsolationSync` deadlocks when called from Swift Concurrency cooperative thread pool

## Description

Calling Credential APIs (e.g. revoke(), remove(), store()) from any async context crashes the app with a thread starvation deadlock on com.apple.root.user-initiated-qos.cooperative. This affects all 2.x SDK versions and is hitting production when a user is logged out.


The root cause is two internal utility functions — [`withIsolationSyncThrowing`](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/CommonSupport/ExpressionUtilities.swift#L107-L131) and [`withIsolationSync`](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/CommonSupport/ExpressionUtilities.swift#L144-L158) — which bridge synchronous code to actor-isolated code by spawning a `Task` and blocking on `DispatchGroup.wait()`:

```swift
// Sources/CommonSupport/ExpressionUtilities.swift L107-L131
public func withIsolationSyncThrowing<T: Sendable>(...) throws -> T {
    let group = DispatchGroup()
    group.enter()
    Task(priority: priority) {
        defer { group.leave() }
        // ...
    }
    group.wait()  // blocks the current thread until the Task finishes
}
```

When called from a cooperative thread, `group.wait()` blocks that thread. The inner `Task` also needs a cooperative thread (to hop to `@CredentialActor`), but the pool is blocked — causing thread starvation and a deadlock crash.

## Expected Behavior

Calling `Credential.revoke()`, `Credential.remove()`, and other `Credential` APIs from `async` contexts (including `Task { }` blocks) should complete without crashing.

## Actual Behavior

The Swift runtime detects that the cooperative thread pool is exhausted and terminates the process with `EXC_BAD_ACCESS (KERN_INVALID_ADDRESS)` or `SIGTRAP`.

### Crashlytics stack trace

```
EXC_BAD_ACCESS KERN_INVALID_ADDRESS 0x0000000000000040
closure #1 in Credential.remove()

Crashed: com.apple.root.user-initiated-qos.cooperative
0  AtBat.Full                     0x2164a98 closure #1 in Credential.remove() + 239 (Credential.swift:239)
1  libswift_Concurrency.dylib     0x628b4 swift::runJobInEstablishedExecutorContext(swift::Job*) + 288
2  libswift_Concurrency.dylib     0x65d1c (anonymous namespace)::ProcessOutOfLineJob::process(swift::Job*) + 444
3  libswift_Concurrency.dylib     0x628a0 swift::runJobInEstablishedExecutorContext(swift::Job*) + 268
4  libswift_Concurrency.dylib     0x63d28 swift_job_runImpl(swift::Job*, swift::SerialExecutorRef) + 156
5  libdispatch.dylib              0x13f48 _dispatch_root_queue_drain + 364
6  libdispatch.dylib              0x146fc _dispatch_worker_thread2 + 180
7  libsystem_pthread.dylib        0x137c _pthread_wqthread + 232
8  libsystem_pthread.dylib        0x8c0 start_wqthread + 8
```

## Reproduction

A self-contained reproduction is included at [`Sources/CooperativePoolDeadlock/main.swift`](Sources/CooperativePoolDeadlock/main.swift). It imports the real SDK modules (`CommonSupport` and `AuthFoundation`) and exercises the actual `withIsolationSyncThrowing` and `@CredentialActor` implementations.

### Build

```bash
swift build --product CooperativePoolDeadlock \
  --sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  --triple arm64-apple-ios13.0-simulator
```

### Run on iPhone Simulator

```bash
xcrun simctl boot "iPhone 16 Pro Max"

SIMCTL_CHILD_LIBDISPATCH_COOPERATIVE_POOL_STRICT=1 \
  xcrun simctl spawn --standalone booted \
  .build/arm64-apple-ios-simulator/debug/CooperativePoolDeadlock
```

> `LIBDISPATCH_COOPERATIVE_POOL_STRICT=1` restricts the cooperative pool to **a single thread**, making a single `withIsolationSyncThrowing` call from an async context sufficient to deadlock. Without the flag the pool is sized to the CPU core count and the deadlock requires saturating all threads — which happens naturally under normal app load (see Crashlytics data above). The `SIMCTL_CHILD_` prefix forwards the env var into the simulator process.

### What the reproduction does

Spawns concurrent `Task`s on the cooperative pool, each calling the SDK's real `withIsolationSyncThrowing` with a `@CredentialActor`-isolated closure — mirroring `Credential.revoke()` → `Credential.remove()`. Once the pool threads are all blocked by `DispatchGroup.wait()`, the inner Tasks cannot be scheduled, and the process deadlocks.

A 5-second watchdog confirms the hang by printing `DEADLOCK CONFIRMED` and exiting with code 1.

### Deadlock pattern

The core trigger is any `async` function calling `withIsolationSyncThrowing`:

```swift
// This is the exact pattern in Credential.revoke()
func revoke() async throws {
    try await oauth2.revoke(token, type: type)

    // DEADLOCK: async function → withIsolationSyncThrowing → group.wait()
    try withIsolationSyncThrowing { @CredentialActor in
        try coordinator.remove(credential: self)
    }
}
```

```swift
Task {
    try await credential.revoke()  // crashes
}
```

## Affected Call Sites

### `withIsolationSyncThrowing` (6 call sites in `Credential.swift`)

| Line | Method | Risk |
|---|---|---|
| [L77](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/User%20Management/Credential.swift#L77) | `Credential.with(id:prompt:authenticationContext:)` | Sync — deadlocks if caller is on cooperative pool |
| [L105](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/User%20Management/Credential.swift#L105) | `Credential.find(where:prompt:authenticationContext:)` | Sync — deadlocks if caller is on cooperative pool |
| [L132](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/User%20Management/Credential.swift#L132) | `Credential.store(_:tags:security:)` | Sync — deadlocks if caller is on cooperative pool |
| [L184](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/User%20Management/Credential.swift#L184) | `Credential.setTags(_:)` | Sync — deadlocks if caller is on cooperative pool |
| [L242](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/User%20Management/Credential.swift#L242) | `Credential.remove()` | Sync — called from async `revoke()` |
| [L285](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/User%20Management/Credential.swift#L285) | `Credential.revoke(type:)` | **`async` — direct deadlock path** |

### `withIsolationSync` (22 call sites across the SDK)

Same `Task` + `DispatchGroup.wait()` pattern, non-throwing variant.

| File | Call sites | Usage |
|---|---|---|
| `Credential.swift` | [L34](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/User%20Management/Credential.swift#L34), [L41](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/User%20Management/Credential.swift#L41), [L51](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/User%20Management/Credential.swift#L51), [L388](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/User%20Management/Credential.swift#L388) | `default`, `allIDs`, `metadata` property getters |
| `CredentialCoordinatorImpl.swift` | [L211](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/User%20Management/Internal/CredentialCoordinatorImpl.swift#L211) | Coordinator internal state |
| `Authentication.swift` | [L63](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/OAuth2/Authentication.swift#L63), [L73](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/AuthFoundation/OAuth2/Authentication.swift#L73) | ID token validation context |
| `AuthorizationCodeFlow.swift` | [L81](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Authentication/AuthorizationCodeFlow.swift#L81), [L86](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Authentication/AuthorizationCodeFlow.swift#L86) | `isAuthenticating`, `context` |
| `DeviceAuthorizationFlow.swift` | [L79](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Authentication/DeviceAuthorizationFlow.swift#L79), [L84](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Authentication/DeviceAuthorizationFlow.swift#L84) | `isAuthenticating`, `context` |
| `JWTAuthorizationFlow.swift` | [L29](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Authentication/JWTAuthorizationFlow.swift#L29), [L38](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Authentication/JWTAuthorizationFlow.swift#L38) | `context`, `isAuthenticating` |
| `ResourceOwnerFlow.swift` | [L33](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Authentication/ResourceOwnerFlow.swift#L33), [L41](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Authentication/ResourceOwnerFlow.swift#L41) | `context`, `isAuthenticating` |
| `SessionTokenFlow.swift` | [L32](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Authentication/SessionTokenFlow.swift#L32), [L40](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Authentication/SessionTokenFlow.swift#L40) | `context`, `isAuthenticating` |
| `TokenExchangeFlow.swift` | [L50](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Authentication/TokenExchangeFlow.swift#L50), [L58](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Authentication/TokenExchangeFlow.swift#L58) | `context`, `isAuthenticating` |
| `SessionLogoutFlow.swift` | [L72](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Logout/SessionLogoutFlow.swift#L72), [L77](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OAuth2Auth/Logout/SessionLogoutFlow.swift#L77) | `inProgress`, `context` |
| `DirectAuthFlow.swift` | [L317](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OktaDirectAuth/DirectAuthFlow.swift#L317), [L325](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OktaDirectAuth/DirectAuthFlow.swift#L325) | `context`, `isAuthenticating` |
| `InteractionCodeFlow.swift` | [L40](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OktaIdxAuth/InteractionCodeFlow.swift#L40), [L47](https://github.com/okta/okta-mobile-swift/blob/5c710b0c982af6beec143cab2385d9755ed0d308/Sources/OktaIdxAuth/InteractionCodeFlow.swift#L47) | `isAuthenticating`, `context` |

## SDK Versions Affected

| Version | Affected |
|---|---|
| **2.0.0 – 2.1.4** (all 2.x releases) | Yes |
| **master** (commit [`5c710b0`](https://github.com/okta/okta-mobile-swift/commit/5c710b0c982af6beec143cab2385d9755ed0d308)) | Yes |
| **1.x** | No — `withIsolationSyncThrowing` / `withIsolationSync` did not exist prior to 2.0.0 |

### Environment

- **Platforms:** All (iOS, macOS, tvOS, watchOS, visionOS)
- **Swift:** 5.10+ / 6.0+
- **Crash thread:** `com.apple.root.user-initiated-qos.cooperative`
- **Top crashing devices (from Crashlytics):** iPhone 16 Pro Max (17%), iPhone 15 Pro Max (11%), iPhone 15 (11%)

### Why this affects a subset of users

The deadlock is not deterministic under normal conditions — it requires all cooperative pool threads to be simultaneously blocked by `DispatchGroup.wait()`. The cooperative pool is sized to the CPU core count (e.g. 6 on an iPhone, 10+ on a Mac), so the crash depends on how much concurrent async work the app is doing at the moment `revoke()` or `remove()` is called. Users who trigger auth operations during periods of high concurrency (background refreshes, parallel network requests, etc.) are more likely to saturate the pool. The top crashing devices in Crashlytics reflect our most popular devices, not necessarily the most vulnerable — devices with fewer cores would be more susceptible.
