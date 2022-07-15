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

#if canImport(CoreImage)
import CoreImage.CIFilterBuiltins

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
#endif

extension DeviceAuthorizationFlow {
    /// A model representing the context and current state for an authorization session.
    public struct Context: Decodable, Equatable, Expires {
        /// The date this context was created.
        public let issuedAt: Date?

        /// The code that should be displayed to the user.
        public let userCode: String
        
        /// The URI the user should be prompted to open in order to authorize the application.
        public let verificationUri: URL
        
        /// A convenience URI that combines the ``verificationUri`` and the ``userCode``, to make a clickable link.
        public let verificationUriComplete: URL?
        
        /// The time interval after which the authorization context will expire.
        public let expiresIn: TimeInterval
        
        enum CodingKeys: String, CodingKey, CaseIterable {
            case issuedAt
            case userCode
            case verificationUri
            case verificationUriComplete
            case expiresIn
            case deviceCode
            case interval
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            issuedAt = try container.decodeIfPresent(Date.self, forKey: .issuedAt) ?? Date()
            deviceCode = try container.decode(String.self, forKey: .deviceCode)
            userCode = try container.decode(String.self, forKey: .userCode)
            verificationUri = try container.decode(URL.self, forKey: .verificationUri)
            verificationUriComplete = try container.decodeIfPresent(URL.self, forKey: .verificationUriComplete)
            expiresIn = try container.decode(TimeInterval.self, forKey: .expiresIn)
            interval = try container.decodeIfPresent(TimeInterval.self, forKey: .interval) ?? 5.0
        }
        
        // MARK: Private / Internal
        let deviceCode: String
        var interval: TimeInterval
        
        #if canImport(CoreImage)
        func generateQRCode() -> CGImage? {
            let uri = verificationUriComplete ?? verificationUri
            guard let data = uri.absoluteString.data(using: .utf8) else {
                return nil
            }
            
            let imageFilter: CIFilter
            if #available(tvOS 13.0, *) {
                let qrFilter = CIFilter.qrCodeGenerator()
                qrFilter.message = data
                imageFilter = qrFilter
            } else {
                guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
                    return nil
                }
                filter.setValue(data, forKey: "message")
                imageFilter = filter
            }
            
            guard let outputImage = imageFilter.outputImage else {
                return nil
            }
            
            let context = CIContext()
            return context.createCGImage(outputImage, from: outputImage.extent)
        }
        
        #if canImport(UIKit)
        /// Generates a QR code representation of the ``verificationUriComplete`` or ``verificationUri`` URI.
        ///
        /// When using this within an image view, 
        @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
        public var qrCode: UIImage? {
            guard let cgImage = generateQRCode() else {
                return nil
            }
            
            return UIImage(cgImage: cgImage)
        }
        #elseif canImport(AppKit)
        /// Generates a QR code representation of the ``verificationUriComplete`` or ``verificationUri`` URI.
        @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
        public var qrCode: NSImage? {
            guard let cgImage = generateQRCode() else {
                return nil
            }
            
            return NSImage(cgImage: cgImage)
        }
        #endif
        #endif
    }
}
