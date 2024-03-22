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

extension String: ClaimConvertable {}
extension Bool: ClaimConvertable {}
extension Int: ClaimConvertable {}
extension Double: ClaimConvertable {}
extension Float: ClaimConvertable {}
extension Array<String>: ClaimConvertable {}
extension Dictionary<String, String>: ClaimConvertable {}
extension URL: ClaimConvertable {}
extension Date: ClaimConvertable {}
extension JWTClaim: ClaimConvertable {}
extension GrantType: ClaimConvertable {}
extension NSString: ClaimConvertable {}
extension NSNumber: ClaimConvertable {}

extension ClaimConvertable where Self == Date {
    public static func claim(_ claim: String,
                             in type: any HasClaims,
                             from value: Any?) -> Self?
    {
        if let time = value as? Int {
            return Date(timeIntervalSince1970: TimeInterval(time))
        }
        
        if let time = value as? String {
            return ISO8601DateFormatter().date(from: time)
        }
        
        return nil
    }
}

extension ClaimConvertable where Self == URL {
    public static func claim(_ claim: String,
                             in type: any HasClaims,
                             from value: Any?) -> Self?
    {
        guard let string = value as? String else { return nil }
        return URL(string: string)
    }
}

extension ClaimConvertable where Self: IsClaim {
    public static func claim(_ claim: String,
                             in type: any HasClaims,
                             from value: Any?) -> Self?
    {
        guard let value = value as? String else { return nil }
        return .init(rawValue: value)
    }
}
