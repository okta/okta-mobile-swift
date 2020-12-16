//
//  IdentityEngine.swift
//  
//
//  Created by Mike Nachbaur on 2020-11-27.
//

import Foundation
import Combine

//@objc(OKTIdentityEngine)
//public class IdentityEngine: NSObject {
//    @objc(OKTIdentityEngineVersion)
//    public enum Version: Int {
//        case v1_0_0
//    }
//
//    public enum Error: Swift.Error {
//        case noIntrospectionObject
//    }
//    
//    public func start(domain domainName: String,
//                      stateHandle handle: StateHandle,
//                      version: Version = Version.latest,
//                      completionHandler: @escaping (Introspect?, Error?) -> Void)
//    {
//        completionHandler(nil, nil)
//    }
//    
////    public func start(domain domainName: String,
////                      stateHandle handle: StateHandle,
////                      version: Version = Version.latest) -> Future<Introspect, Error>
////    {
////        return Future<Introspect, Error> { (promise) in
////            self.start(domain: domainName, stateHandle: handle, version: version) { (introspect, error) in
////                if let error = error {
////                    promise(.failure(error))
////                } else if let introspect = introspect {
////                    promise(.success(introspect))
////                } else {
////                    promise(.failure(Error.noIntrospectionObject))
////                }
////            }
////        }
////    }
//}
