//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension WebAuthn {
    /**
     This member contains the type of the public key credential the caller is referring to.
     
     - Note: [W3C Reccomendation](https://www.w3.org/TR/webauthn/#dom-publickeycredentialdescriptor-type)
     */
    public enum AuthenticatorTransport: String, Codable {
        /// Indicates the respective authenticator can be contacted over Bluetooth Smart (Bluetooth Low Energy / BLE).
        case ble
        
        /// Indicates the respective authenticator can be contacted over Near Field Communication (NFC).
        case nfc
        
        /// Indicates the respective authenticator is contacted using a client device-specific transport, i.e., it is a platform authenticator. These authenticators are not removable from the client device.
        case platform = "internal"
        
        /// Indicates the respective authenticator can be contacted over removable USB
        case usb
        
        /// Indicates the respective authenticator can be contacted over ISO/IEC 7816 smart card with contacts.
        case smartCard = "smart-card"
        
        /// Indicates the respective authenticator can be contacted using a combination of (often separate) data-transport and proximity mechanisms. This supports, for example, authentication on a desktop computer using a smartphone.
        case hybrid
    }
}
