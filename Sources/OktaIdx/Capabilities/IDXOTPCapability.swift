//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Capability to recover an account.
public struct OTPCapability: Capability, Sendable, Hashable, Equatable {
    /// Mime type for the associated QR code image data.
    public let mimeType: String
    
    /// The data contents for the QR code image.
    public let imageData: Data
    
    /// For OTP providers that support it, the shared secret supplied along with the QR code.
    public let sharedSecret: String?
}

#if canImport(UIKit)
import UIKit
extension OTPCapability {
    /// Image representation of the QR code.
    public var image: UIImage? {
        UIImage(data: imageData)
    }
}
#elseif canImport(AppKit)
import AppKit
extension OTPCapability {
    /// Image representation of the QR code.
    public var image: NSImage? {
        NSImage(data: imageData)
    }
}
#endif


