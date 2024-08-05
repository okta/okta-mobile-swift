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

// swiftlint:disable function_body_length
// swiftlint:disable cyclomatic_complexity
extension JWTClaim: RawRepresentable, Equatable {
    public typealias RawValue = String

    public init?(rawValue: String) {
        switch rawValue {
        case "iss":
            self = .issuer
        case "ver":
            self = .version
        case "uid":
            self = .userId
        case "idp":
            self = .identityProvider
        case "sub":
            self = .subject
        case "aud":
            self = .audience
        case "exp":
            self = .expirationTime
        case "nbf":
            self = .notBefore
        case "iat":
            self = .issuedAt
        case "jti":
            self = .jwtId
        case "name":
            self = .name
        case "given_name":
            self = .givenName
        case "family_name":
            self = .familyName
        case "middle_name":
            self = .middleName
        case "nickname":
            self = .nickname
        case "preferred_username":
            self = .preferredUsername
        case "profile":
            self = .profile
        case "picture":
            self = .picture
        case "website":
            self = .website
        case "email":
            self = .email
        case "email_verified":
            self = .emailVerified
        case "gender":
            self = .gender
        case "birthdate":
            self = .birthdate
        case "zoneinfo":
            self = .zoneinfo
        case "locale":
            self = .locale
        case "phone_number":
            self = .phoneNumber
        case "phone_number_verified":
            self = .phoneNumberVerified
        case "address":
            self = .address
        case "updated_at":
            self = .updatedAt
        case "azp":
            self = .authorizedParty
        case "nonce":
            self = .nonce
        case "auth_time":
            self = .authTime
        case "at_hash":
            self = .accessTokenHash
        case "c_hash":
            self = .codeHash
        case "acr":
            self = .authContextClassReference
        case "amr":
            self = .authMethodsReference
        case "sub_jwk":
            self = .subjectPublicKey
        case "cnf":
            self = .confirmation
        case "sip_from_tag":
            self = .sipFromTag
        case "sip_date":
            self = .sipDate
        case "sip_callid":
            self = .sipCallId
        case "sip_cseq_num":
            self = .sipCSeqNum
        case "sip_via_branch":
            self = .sipViaBranch
        case "orig":
            self = .originatingIdentity
        case "dest":
            self = .destinationIdentity
        case "mky":
            self = .mediaKeyFingerprint
        case "events":
            self = .events
        case "toe":
            self = .timeOfEvent
        case "txn":
            self = .transactionId
        case "rph":
            self = .resourcePriorityHeader
        case "sid":
            self = .sessionId
        case "vot":
            self = .vectorOfTrust
        case "vtm":
            self = .vectorOfTrustMark
        case "attest":
            self = .attestationLevel
        case "origid":
            self = .originatingId
        case "act":
            self = .actor
        case "scp":
            self = .scope
        case "cid":
            self = .clientId
        case "may_act":
            self = .authorizedActor
        case "jcard":
            self = .jcardData
        case "at_use_nbr":
            self = .maxAPIRequestCount
        case "div":
            self = .divertedTarget
        case "opt":
            self = .originalPassport
        case "vc":
            self = .verifiableCredential
        case "vp":
            self = .verifiablePresentation
        case "sph":
            self = .sipPriorityHeader
        case "ace_profile":
            self = .aceProfile
        case "cnonce":
            self = .clientNonce
        case "exi":
            self = .expiresIn
        case "roles":
            self = .roles
        case "groups":
            self = .groups
        case "entitlements":
            self = .entitlements
        case "token_introspection":
            self = .tokenIntrospection
        case "nonce_supported":
            self = .nonceSupported
        case "real_user_status":
            self = .realUserStatus
        case "is_private_email":
            self = .isPrivateEmail
        case "transfer_sub":
            self = .transferSubject
        default:
            self = .custom(rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .issuer:
            return "iss"
        case .version:
            return "ver"
        case .userId:
            return "uid"
        case .identityProvider:
            return "idp"
        case .subject:
            return "sub"
        case .audience:
            return "aud"
        case .expirationTime:
            return "exp"
        case .notBefore:
            return "nbf"
        case .issuedAt:
            return "iat"
        case .jwtId:
            return "jti"
        case .name:
            return "name"
        case .givenName:
            return "given_name"
        case .familyName:
            return "family_name"
        case .middleName:
            return "middle_name"
        case .nickname:
            return "nickname"
        case .preferredUsername:
            return "preferred_username"
        case .profile:
            return "profile"
        case .picture:
            return "picture"
        case .website:
            return "website"
        case .email:
            return "email"
        case .emailVerified:
            return "email_verified"
        case .gender:
            return "gender"
        case .birthdate:
            return "birthdate"
        case .zoneinfo:
            return "zoneinfo"
        case .locale:
            return "locale"
        case .phoneNumber:
            return "phone_number"
        case .phoneNumberVerified:
            return "phone_number_verified"
        case .address:
            return "address"
        case .updatedAt:
            return "updated_at"
        case .authorizedParty:
            return "azp"
        case .nonce:
            return "nonce"
        case .authTime:
            return "auth_time"
        case .accessTokenHash:
            return "at_hash"
        case .codeHash:
            return "c_hash"
        case .authContextClassReference:
            return "acr"
        case .authMethodsReference:
            return "amr"
        case .subjectPublicKey:
            return "sub_jwk"
        case .confirmation:
            return "cnf"
        case .sipFromTag:
            return "sip_from_tag"
        case .sipDate:
            return "sip_date"
        case .sipCallId:
            return "sip_callid"
        case .sipCSeqNum:
            return "sip_cseq_num"
        case .sipViaBranch:
            return "sip_via_branch"
        case .originatingIdentity:
            return "orig"
        case .destinationIdentity:
            return "dest"
        case .mediaKeyFingerprint:
            return "mky"
        case .events:
            return "events"
        case .timeOfEvent:
            return "toe"
        case .transactionId:
            return "txn"
        case .resourcePriorityHeader:
            return "rph"
        case .sessionId:
            return "sid"
        case .vectorOfTrust:
            return "vot"
        case .vectorOfTrustMark:
            return "vtm"
        case .attestationLevel:
            return "attest"
        case .originatingId:
            return "origid"
        case .actor:
            return "act"
        case .scope:
            return "scp"
        case .clientId:
            return "cid"
        case .authorizedActor:
            return "may_act"
        case .jcardData:
            return "jcard"
        case .maxAPIRequestCount:
            return "at_use_nbr"
        case .divertedTarget:
            return "div"
        case .originalPassport:
            return "opt"
        case .verifiableCredential:
            return "vc"
        case .verifiablePresentation:
            return "vp"
        case .sipPriorityHeader:
            return "sph"
        case .aceProfile:
            return "ace_profile"
        case .clientNonce:
            return "cnonce"
        case .expiresIn:
            return "exi"
        case .roles:
            return "roles"
        case .groups:
            return "groups"
        case .entitlements:
            return "entitlements"
        case .tokenIntrospection:
            return "token_introspection"
        case .nonceSupported:
            return "nonce_supported"
        case .realUserStatus:
            return "real_user_status"
        case .isPrivateEmail:
            return "is_private_email"
        case .transferSubject:
            return "transfer_sub"
        case .custom(let name):
            return name
        }
    }
}
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
