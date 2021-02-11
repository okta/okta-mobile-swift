//
//  Bundle+Extensions.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2021-02-10.
//

import Foundation

extension Bundle {
    static var resourcesPath: URL {
        #if os(macOS)
        if let bundle = Bundle.allBundles.first(where: { $0.bundlePath.hasSuffix(".xctest") }) {
            return bundle.bundleURL.deletingLastPathComponent().appendingPathComponent("OktaIdx_OktaIdxTests.bundle")
        }
        fatalError("Couldn't find the products directory")
        #else
        return Bundle(for: IDXClientAPIv1Mock.self).bundleURL
        #endif
    }
    
    static func testResource(folderName: String? = nil, fileName: String) -> URL {
        var path = resourcesPath.appendingPathComponent("Resources")
        if let folderName = folderName {
            path.appendPathComponent(folderName)
        }
        path.appendPathComponent(fileName)
        path.appendPathExtension("json")
        return path
    }
}
