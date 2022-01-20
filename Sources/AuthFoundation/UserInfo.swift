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

/// User profile information.
public class UserInfo: Codable, JSONDecodable {
    public let sub: String
    
    public let name: String?
    public let givenName: String?
    public let familyName: String?
    public let middleName: String?
    public let nickname: String?
    public let preferredUsername: String?

    public let email: String?
    public let emailVerified: Bool?
    
    public let phoneNumber: String?
    public let phoneNumberVerified: Bool?

    public let address: [String: String]?

    public let gender: String?
    public let birthdate: String?

    public let updatedAt: Date?
    
    private let locale: String?
    public lazy var userLocale: Locale? = {
        guard let locale = locale else {
            return nil
        }

        return Locale(identifier: locale)
    }()
    
    private let zoneinfo: String?
    public lazy var zoneInfo: TimeZone? = {
        guard let zoneinfo = zoneinfo else {
            return nil
        }

        return TimeZone(identifier: zoneinfo)
    }()

//    public let claims: [Claim: Any]?

    public static let jsonDecoder: JSONDecoder = {
        let result = JSONDecoder()
        result.keyDecodingStrategy = .convertFromSnakeCase
        result.dateDecodingStrategy = .secondsSince1970
        return result
    }()
}
