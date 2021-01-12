//
//  IdentityEngineVersion+Extension.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-08.
//

import Foundation

extension IDXClient.Version: RawRepresentable {
    /// References the latest version of the SDK
    public static let latest = v1_0_0

    public typealias RawValue = String
    public var rawValue: RawValue {
        switch self {
            case .v1_0_0:
                return "1.0.0"
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
            case "1.0.0":
                self = .v1_0_0
            default:
                return nil
        }
    }
    
    internal func clientImplementation(with configuration: IDXClient.Configuration) -> IDXClientAPIImpl {
        switch self {
        case .v1_0_0:
            return IDXClient.APIVersion1(with: configuration)
        }
    }
}
