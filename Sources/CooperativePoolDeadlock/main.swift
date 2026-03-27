// Reproduction: withIsolationSyncThrowing deadlocks on the cooperative pool.
//
// Imports the real SDK modules and calls `withIsolationSyncThrowing` with a
// @CredentialActor-isolated closure from concurrent Tasks — the same pattern
// as Credential.revoke() → Credential.remove().
//
// Build:
//   swift build --product CooperativePoolDeadlock \
//     --sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
//     --triple arm64-apple-ios13.0-simulator
//
// Run:
//   SIMCTL_CHILD_LIBDISPATCH_COOPERATIVE_POOL_STRICT=1 \
//     xcrun simctl spawn --standalone booted \
//     .build/arm64-apple-ios-simulator/debug/CooperativePoolDeadlock

import Foundation
import CommonSupport
import AuthFoundation

func syncRemove() throws -> String {
    try withIsolationSyncThrowing { @CredentialActor in
        "removed"
    }
}

let cpuCount = ProcessInfo.processInfo.activeProcessorCount
let strictPool = ProcessInfo.processInfo
    .environment["LIBDISPATCH_COOPERATIVE_POOL_STRICT"] == "1"
let effectivePoolWidth = strictPool ? 1 : cpuCount
let taskCount = max(effectivePoolWidth * 4, 8)

print("""
CPU cores: \(cpuCount)
LIBDISPATCH_COOPERATIVE_POOL_STRICT: \(strictPool ? "1 (pool forced to 1 thread)" : "not set (pool = \(cpuCount) threads)")
Spawning \(taskCount) tasks, each calling withIsolationSyncThrowing → DispatchGroup.wait()

Expected: the Swift runtime detects thread pool starvation and kills
the process with SIGTRAP (signal 5) — the same crash seen in production.
""")
fflush(stdout)

let work = Task.detached {
    await withTaskGroup(of: String?.self) { group in
        for _ in 0..<taskCount {
            group.addTask { try? syncRemove() }
        }
        for await _ in group {}
    }
}

let watchdog = DispatchSource.makeTimerSource(queue: .global())
watchdog.schedule(deadline: .now() + 5)
watchdog.setEventHandler {
    print("""
    DEADLOCK CONFIRMED
    All cooperative threads blocked by DispatchGroup.wait() inside
    withIsolationSyncThrowing (CommonSupport/ExpressionUtilities.swift).
    """)
    fflush(stdout)
    exit(1)
}
watchdog.resume()

Task.detached {
    _ = await work.value
    watchdog.cancel()
    print("Tasks completed (pool was not saturated — re-run with LIBDISPATCH_COOPERATIVE_POOL_STRICT=1)")
    fflush(stdout)
    exit(0)
}

dispatchMain()
