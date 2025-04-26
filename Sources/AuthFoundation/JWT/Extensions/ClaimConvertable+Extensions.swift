//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

@_documentation(visibility: private)
extension String: ClaimConvertable {}

@_documentation(visibility: private)
extension Bool: ClaimConvertable {}

@_documentation(visibility: private)
extension Int: ClaimConvertable {}

@_documentation(visibility: private)
extension Double: ClaimConvertable {}

@_documentation(visibility: private)
extension Float: ClaimConvertable {}

@_documentation(visibility: private)
extension JWTClaim: ClaimConvertable {}

@_documentation(visibility: private)
extension GrantType: ClaimConvertable {}

#if swift(<6.0)
extension NSString: @unchecked Sendable, ClaimConvertable {}
#else
@_documentation(visibility: private)
extension NSString: @unchecked @retroactive Sendable, ClaimConvertable {}
#endif

@_documentation(visibility: private)
extension NSNumber: ClaimConvertable {}

@_documentation(visibility: private)
extension URL: ClaimConvertable {
    public static func convert(from value: Any?) -> Self? {
        guard let string = value as? String else { return nil }
        return URL(string: string)
    }
}

@_documentation(visibility: private)
extension Date: ClaimConvertable {
    public static func convert(from value: Any?) -> Self? {
        if let time = value as? Int {
            return Date(timeIntervalSince1970: TimeInterval(time))
        }
        
        if let time = value as? String {
            if let date = ISO8601DateFormatter().date(from: time) {
                return date
            }
            
            if let date = httpDateFormatter.date(from: time) {
                return date
            }
        }
        
        return nil
    }
}

@_documentation(visibility: private)
extension ClaimConvertable where Self: RawRepresentable {
    public static func convert(from value: Any?) -> Self? {
        if let value = value as? Self {
            return value
        }
        
        if let value = value as? Self.RawValue {
            return Self(rawValue: value)
        }

        return nil
    }
}

extension ClaimConvertable where Self: APIRequestArgument {}
