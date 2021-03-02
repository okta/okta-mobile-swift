/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

extension IDXClient.APIVersion1.AcceptType {
    private static let urlEncodedString = "application/x-www-form-urlencoded"
    private static let jsonString = "application/json"
    private static let ionJsonString = "application/ion+json"
    
    init?(rawValue: String) {
        var version: String? = nil
        if let range = rawValue.range(of: "okta-version=") {
            version = String(rawValue.suffix(from: range.upperBound))
        }

        if rawValue == IDXClient.APIVersion1.AcceptType.urlEncodedString {
            self = .formEncoded
        } else if rawValue.hasPrefix(IDXClient.APIVersion1.AcceptType.jsonString) {
            self = .json(version: version)
        } else if rawValue.hasPrefix(IDXClient.APIVersion1.AcceptType.ionJsonString) {
            self = .ionJson(version: version)
        } else {
            return nil
        }
    }
    
    func encodedData(with parameters: [String:Any]) throws -> Data? {
        switch self {
        case .formEncoded:
            guard let parameters = parameters as? [String:String] else {
                throw IDXClientError.invalidRequestData
            }
            return URLRequest.idxURLFormEncodedString(for: parameters)?.data(using: .utf8)
        case .json: fallthrough
        case .ionJson:
            var opts: JSONSerialization.WritingOptions = []
            if #available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, macOS 10.13, *) {
                opts.insert(.sortedKeys)
            }
            
            return try JSONSerialization.data(withJSONObject: parameters, options: opts)
        }
    }
    
    public func stringValue() -> String {
        switch self {
        case .formEncoded:
            return IDXClient.APIVersion1.AcceptType.urlEncodedString
        case .json(version: let version):
            if version == nil {
                return IDXClient.APIVersion1.AcceptType.jsonString
            } else {
                return "\(IDXClient.APIVersion1.AcceptType.jsonString); okta-version=\(version!)"
            }
        case .ionJson(version: let version):
            if version == nil {
                return IDXClient.APIVersion1.AcceptType.ionJsonString
            } else {
                return "\(IDXClient.APIVersion1.AcceptType.ionJsonString); okta-version=\(version!)"
            }
        }
    }
}
