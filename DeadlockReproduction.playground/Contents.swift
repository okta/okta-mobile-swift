import UIKit
import PlaygroundSupport
// Note: Ensure the 'AuthFoundation' target is built and available to this Playground.
import AuthFoundation

// Enable indefinite execution to allow async tasks to run
PlaygroundPage.current.needsIndefiniteExecution = true

print("🏁 Starting Deadlock Reproduction")

// 1. BACKGROUND THREAD
// Initialize OAuth2Client on a detached background task.
// This triggers:
//   -> OAuth2Client.init
//   -> SDKVersion.authFoundation (Lazy Static Init)
//   -> SDKVersion.register (ACQUIRES LOCK)
//   -> UIDevice.current.systemVersion (DispatchQueue.main.sync calls)
Task.detached {
    print("Background: Initializing OAuth2Client... (Acquiring Lock)")
    
    // This line triggers the registration lock
    let client = OAuth2Client(issuerURL: URL(string: "https://example.com")!,
                              clientId: "repro-client",
                              scope: "openid")
    
    print("Background: ✅ Initialization Complete! (Lock Released)")
}

// 2. MAIN THREAD

print("Main: Accessing SDKVersion.userAgent... (Requiring Lock)")

// If the bug exists, this line will hang indefinitely because:
// - Main Thread is stuck here waiting for SDKVersion.lock
// - Background Thread is holding SDKVersion.lock waiting for Main Thread (to get UIDevice info)
let agent = SDKVersion.userAgent

print("Main: ✅ UserAgent retrieved: \(agent)")
print("🎉 NO DEADLOCK DETECTED")

PlaygroundPage.current.finishExecution()
