//
//  File.swift
//  
//
//  Created by Mike Nachbaur on 2020-11-27.
//

import Foundation

@objc(OKTIdentityEngine)
public class IdentityEngine: NSObject {
    @objc(OKTIdentityEngineVersion)
    public enum Version: String {
        case 1_0_0 = "1.0.0"
        static let latest = 1_0_0
    }

    public func start(domain domainName: String,
                      stateHandle handle: Any,
                      version: Version = Version.latest) -> Future<Any>
    {
        
    }
    
}
