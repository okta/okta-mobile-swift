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

/// List of registered and public claims.
public enum Claim: Codable {
    /// Issuer
    case issuer

    case version

    case userId

    case identityProvider

    /// Subject
    case subject

    /// Audience
    case audience

    /// Expiration Time
    case expirationTime

    /// Not Before
    case notBefore

    /// Issued At
    case issuedAt

    /// JWT ID
    case jwtId

    /// Full name
    case name

    /// Given name(s) or first name(s)
    case givenName

    /// Surname(s) or last name(s)
    case familyName

    /// Middle name(s)
    case middleName

    /// Casual name
    case nickname

    /// Shorthand name by which the End-User wishes to be referred to
    case preferredUsername

    /// Profile page URL
    case profile

    /// Profile picture URL
    case picture

    /// Web page or blog URL
    case website

    /// Preferred e-mail address
    case email

    /// True if the e-mail address has been verified; otherwise false
    case emailVerified

    /// Gender
    case gender

    /// Birthday
    case birthdate

    /// Time zone
    case zoneinfo

    /// Locale
    case locale

    /// Preferred telephone number
    case phoneNumber

    /// True if the phone number has been verified; otherwise false
    case phoneNumberVerified

    /// Preferred postal address
    case address

    /// Time the information was last updated
    case updatedAt

    /// Authorized party - the party to which the ID Token was issued
    case authorizedParty

    /// Value used to associate a Client session with an ID Token
    case nonce

    /// Time when the authentication occurred
    case authTime

    /// Access Token hash value
    case accessTokenHash

    /// Code hash value
    case codeHash

    /// Authentication Context Class Reference
    case authContextClassReference

    /// Authentication Methods References
    case authMethodsReference

    /// Public key used to check the signature of an ID Token
    case subjectPublicKey

    /// Confirmation
    case confirmation

    /// SIP From tag header field parameter value
    case sipFromTag

    /// SIP Date header field value
    case sipDate

    /// SIP Call-Id header field value
    case sipCallId

    /// SIP CSeq numeric header field parameter value
    case sipCSeqNum

    /// SIP Via branch header field parameter value
    case sipViaBranch

    /// Originating Identity String
    case originatingIdentity

    /// Destination Identity String
    case destinationIdentity

    /// Media Key Fingerprint String
    case mediaKeyFingerprint

    /// Security Events
    case events

    /// Time of Event
    case timeOfEvent

    /// Transaction Identifier
    case transactionId

    /// Resource Priority Header Authorization
    case resourcePriorityHeader

    /// Session ID
    case sessionId

    /// Vector of Trust value
    case vectorOfTrust

    /// Vector of Trust trustmark URL
    case vectorOfTrustMark

    /// Attestation level as defined in SHAKEN framework
    case attestationLevel

    /// Originating Identifier as defined in SHAKEN framework
    case originatingId

    /// Actor
    case actor

    /// Scope Values
    case scope

    /// Client Identifier
    case clientId

    /// "Authorized Actor - the party that is authorized to become the actor"
    case authorizedActor

    /// jCard data
    case jcardData

    /// Number of API requests for which the access token can be used
    case maxAPIRequestCount

    /// Diverted Target of a Call
    case divertedTarget

    /// Original PASSporT (in Full Form)
    case originalPassport

    /// Verifiable Credential as specified in the W3C Recommendation
    case verifiableCredential

    /// Verifiable Presentation as specified in the W3C Recommendation
    case verifiablePresentation

    /// SIP Priority header field
    case sipPriorityHeader

    /// "The ACE profile a token is supposed to be used with."
    case aceProfile

    /// A nonce previously provided to the AS by the RS via the client.  Used to verify token freshness when the RS cannot synchronize its clock with the AS."
    case clientNonce

    /// "Expires in.  Lifetime of the token in seconds from the time the RS first sees it.  Used to implement a weaker from of token expiration for devices that cannot synchronize their internal clocks."
    case expiresIn

    /// Roles
    case roles

    /// Groups
    case groups

    /// Entitlements
    case entitlements

    /// Token introspection response
    case tokenIntrospection

    /// Custom claim with the given name
    case custom(_ name: String)
}

/// Used by classes that contains OAuth2 claims.
///
/// This provides common conveniences for interacting with user or token information within those claims. For example, iterating through ``allClaims-4c54a`` or using keyed subscripting to access specific claims.
public protocol HasClaims {
    /// Returns the collection of claims this object contains.
    ///
    /// > Note: This will only return the list of official claims defined in the ``Claim`` enum. For custom claims, please see the ``customClaims`` property.
    var claims: [Claim] { get }
    
    /// Returns the collection of custom claims this object contains.
    ///
    /// Unlike the ``claims`` property, this returns values as strings.
    var customClaims: [String] { get }
    
    /// All claims, across both standard ``claims`` and ``customClaims``.
    var allClaims: [String] { get }
    
    /// Raw paylaod of claims, as a dictionary representation.
    var payload: [String: Any] { get }
    
    /// Return the given claim's value.
    subscript<T>(_ claim: Claim) -> T? { get }

    /// Return the given claim's value.
    subscript<T>(_ claim: String) -> T? { get }
    
    /// Return the value of the requested claim, for the given type.
    func value<T>(_ type: T.Type, for key: String) -> T?
}

public extension HasClaims {
    subscript<T>(_ claim: Claim) -> T? {
        self[claim.rawValue]
    }
    
    subscript<T>(_ claim: String) -> T? {
        if T.self == Date.self {
            guard let time = value(Int.self, for: claim) else { return nil }
            return Date(timeIntervalSince1970: TimeInterval(time)) as? T
        } else {
            return value(T.self, for: claim)
        }
    }
    
    var allClaims: [String] {
        Array([
            claims.map(\.rawValue),
            customClaims
        ].joined())
    }
    
    /// The subject of the resource, if available.
    var subject: String? { self[.subject] }
    
    /// The date the resource was updated at.
    var updatedAt: Date? { self[.updatedAt] }
    
    /// The date at which authentication occurred.
    var authTime: Date? { self[.authTime] }
    
    /// The full name of the resource.
    var name: String? { self[.name] }
    
    /// The person's given, or first, name.
    var givenName: String? { self[.givenName] }
    
    /// The person's family, or last, name.
    var familyName: String? { self[.familyName] }
    
    /// The person's middle name.
    var middleName: String? { self[.middleName] }
    
    /// The person's nickname.
    var nickname: String? { self[.nickname] }
    
    /// The person's preferred username.
    var preferredUsername: String? { self[.preferredUsername] }

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
    /// The person's name components, pre-assigned to a PersonNameComponents object.
    ///
    /// This property can be used as a convenience to generate a string representation of the user's name, based on the user's current locale.
    ///
    /// For example:
    ///
    /// ```swift
    /// let formatter = PersonNameComponentsFormatter()
    /// formatter.style = .medium
    ///
    /// let name = formatter.string(from: userInfo.nameComponents)
    /// ```
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    var nameComponents: PersonNameComponents {
        PersonNameComponents(givenName: givenName,
                             middleName: middleName,
                             familyName: familyName,
                             nameSuffix: nickname,
                             nickname: nickname)
    }
    #endif
    
    /// The address components for this user.
    var address: [String: String]? { self[.address] }
    
    /// The user's profile address.
    var profile: String? { self[.profile] }
    
    /// The user's picture address.
    var picture: String? { self[.picture] }
    
    /// The user's website address.
    var website: String? { self[.website] }

    /// The user's email address.
    var email: String? { self[.email] }
    
    /// Indicates whether or not the user's email address has been verified.
    var emailVerified: Bool? { self[.emailVerified] }

    /// The user's phone number.
    var phoneNumber: String? { self[.phoneNumber] }
    
    /// Indicates whether or not the user's phone number has been verified.
    var phoneNumberVerified: Bool? { self[.phoneNumberVerified] }

    /// The user's gender.
    var gender: String? { self[.gender] }
    
    /// The user's birth date.
    var birthdate: String? { self[.birthdate] }

    /// The user's timezone code.
    var zoneinfo: String? { self[.zoneinfo] }
    
    /// The user's timezone, represented as a TimeZone object.
    var timeZone: TimeZone? {
        guard let zoneinfo = zoneinfo else {
            return nil
        }

        return TimeZone(identifier: zoneinfo)
    }
    
    /// The user's locale.
    var locale: String? { self[.locale] }
    
    /// The user's locale, represnted as a Locale object.
    var userLocale: Locale? {
        guard let locale = locale else {
            return nil
        }

        return Locale(identifier: locale)
    }
    
    /// Returns the Authentication Context Class Reference for this token.
    var authenticationClass: String? { self[.authContextClassReference] }
    
    /// The list of authentication methods included in this token.
    ///
    /// ```swift
    /// if jwt.authenticationMethods?.contains("mfa") {
    ///   // The user authenticated with an MFA factor.
    /// }
    /// ```
    var authenticationMethods: [String]? { self[.authMethodsReference] }
}
