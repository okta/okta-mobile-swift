//
//  IdentityEngineVersion+Extension.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-08.
//

import Foundation

extension IDXClient.Version {
    internal func clientImplementation(with configuration: IDXClient.Configuration) -> IDXClientAPIImpl {
        switch self {
        case .v1_0_0:
            return IDXClient.APIVersion1(with: configuration)
        }
    }
}
