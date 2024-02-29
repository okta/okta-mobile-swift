//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import Foundation
import AuthFoundation

#if canImport(UIKit)
import UIKit
#endif

#if os(watchOS)
import WatchKit
#endif

extension Keychain {
    static let deviceIdentifierKey = "com.okta.mobile.deviceIdentifier"
}

extension InteractionCodeFlow {
    static var systemDeviceIdentifier: UUID? {
        #if canImport(UIKit) && (os(iOS) || os(macOS) || os(tvOS))
        if let uuid = UIDevice.current.identifierForVendor {
            return uuid
        }
        #elseif os(watchOS)
        if let uuid = WKInterfaceDevice.current().identifierForVendor {
            return uuid
        }
        #endif
        
        return nil
    }
    
    static var keychainDeviceIdentifier: UUID? {
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
        if let data = try? Keychain.Search(account: Keychain.deviceIdentifierKey).get().value,
           let string = String(data: data, encoding: .utf8),
           let uuid = UUID(uuidString: string)
        {
            return uuid
        }
        
        let uuid = UUID()
        guard let uuidData = uuid.uuidString.data(using: .utf8) else {
            return nil
        }
        
        do {
            _ = try Keychain.Item(account: Keychain.deviceIdentifierKey,
                                  value: uuidData).save()
            return uuid
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
    
    /// Unique identifier for this device, encoded to limit the character count. This is used within
    /// an outgoing Cookie named `dt` to enable "Remember this device" trust options within OIE.
    var deviceIdentifierString: String? {
        guard let identifier = deviceIdentifier ?? Self.systemDeviceIdentifier ?? Self.keychainDeviceIdentifier
        else {
            return nil
        }

        var bytes = identifier.uuid
        let data = Data(bytes: &bytes, count: 16)
        let deviceToken = data.base64EncodedString()

        return deviceToken
    }
}

extension InteractionCodeFlow.Option {
    var includeInInteractRequest: Bool {
        switch self {
        case .omitDeviceToken: return false
        default: return true
        }
    }
}
