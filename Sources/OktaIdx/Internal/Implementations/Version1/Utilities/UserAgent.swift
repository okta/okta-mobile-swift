//
//  UserAgent.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2021-02-11.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

internal func deviceModel() -> String {
    var system = utsname()
    uname(&system)
    let model = withUnsafePointer(to: &system.machine.0) { ptr in
        return String(cString: ptr)
    }
    return model
}

internal func buildUserAgent() -> String {
    var components: [String] = []
    
    // IDX framework version
    if let infoDictionary = Bundle(for: IDXClient.self).infoDictionary,
       let version = infoDictionary["CFBundleShortVersionString"] as? String
    {
        components.append("okta-idx-swift/\(version)")
    }
    
    // Main app version
    if let infoDictionary = Bundle.main.infoDictionary,
       let version = infoDictionary["CFBundleShortVersionString"] ?? infoDictionary[kCFBundleVersionKey as String] as? String,
       let name = infoDictionary["CFBundleName"] as? String
    {
        components.append("\(name)/\(version)")
    }

    // CFNetwork version (since that's included in the default useragent string)
    if let infoDictionary = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary,
       let version = infoDictionary[kCFBundleVersionKey as String] as? String
    {
        components.append("CFNetwork/\(version)")
    }

    // Device model
    components.append("Device/\(deviceModel())")

    // OS type and version
    #if canImport(UIKit)
    let osName = UIDevice.current.systemName
    let osVersion = UIDevice.current.systemVersion
    components.append("\(osName)/\(osVersion)")
    #elseif os(macOS)
    let osVersion = ProcessInfo.processInfo.operatingSystemVersion
    components.append("macOS/\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)")
    #endif
    
    return components.joined(separator: " ")
}
